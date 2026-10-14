"""Repaired legacy pipeline regression tests, Python 3 standard library only.

Run each project independently because original module names overlap.
The B implementations intentionally schedule RAW dependencies using three NOPs.
The C implementation runs dense dependencies and checks actual load-use stalls.
No RTL is changed. Generated benches and results go to --output-dir.
"""
from pathlib import Path
import os, subprocess, json, tempfile, random, argparse, shutil

REPO=Path(__file__).resolve().parents[1]
ROOT=REPO
parser=argparse.ArgumentParser(description="Verify the three repaired legacy pipeline projects against an independent sequential ISA oracle.")
parser.add_argument('--iverilog', default='iverilog')
parser.add_argument('--vvp', default='vvp')
parser.add_argument('--iverilog-base', type=Path)
parser.add_argument('--output-dir', type=Path, default=REPO/'.verification-build/repaired-pipeline')
args=parser.parse_args()
IV=Path(shutil.which(args.iverilog) or args.iverilog).resolve()
VV=Path(shutil.which(args.vvp) or args.vvp).resolve()
BASE=['-B',args.iverilog_base.resolve()] if args.iverilog_base else []
os.environ['PATH']=str(IV.parent)+os.pathsep+os.environ.get('PATH','')
BUILD=args.output_dir.resolve()
BUILD.mkdir(parents=True,exist_ok=True)
results=[]

def command(args,timeout=30):
    with tempfile.TemporaryFile() as out, tempfile.TemporaryFile() as err:
        p=subprocess.Popen(list(map(str,args)),cwd=ROOT,stdin=subprocess.DEVNULL,stdout=out,stderr=err)
        try: rc=p.wait(timeout=timeout)
        except subprocess.TimeoutExpired: p.kill();p.wait();rc=-999
        out.seek(0);err.seek(0)
        return {'returncode':rc,'stdout':out.read().decode(errors='replace'),'stderr':err.read().decode(errors='replace')}

def run(rel,top,tb,case):
    out=BUILD/(case+'.vvp')
    files=sorted((REPO/'sources'/rel/'rtl').glob('*.v'))
    cc=command([IV,*BASE,'-g2012','-Wall','-s',top,'-o',out,*files,tb])
    sim=command([VV,out]) if cc['returncode']==0 else None
    row={'case':case,'project':rel,'top':top,'source_files':[p.relative_to(REPO).as_posix() for p in files], 'testbench':str(tb), 'compile':cc,'simulation':sim, 'passed':bool(cc['returncode']==0 and sim and sim['returncode']==0 and 'PASS ' in sim['stdout'])}
    results.append(row)
    print(case, 'compile='+str(cc['returncode']), 'sim='+str(sim['returncode'] if sim else None),
          (sim['stdout']+sim['stderr'] if sim else cc['stdout']+cc['stderr']).strip(),flush=True)

def inst_i(op,rs,rt,imm): return (op<<26)|(rs<<21)|(rt<<16)|(imm&65535)
def inst_r(rs,rt,rd,fn): return (rs<<21)|(rt<<16)|(rd<<11)|fn
def signed(n): return n if n<0x80000000 else n-0x100000000
def reference(code,regs,mem):
    regs=list(regs);mem=list(mem);pc=0
    for _ in range(100000):
        if pc>=len(code): return regs,mem
        x=code[pc];op=x>>26;rs=(x>>21)&31;rt=(x>>16)&31;rd=(x>>11)&31;imm=x&65535
        if imm&32768:imm-=65536
        npc=pc+1;write=None
        if op==0:
            fn=x&63;a=regs[rs];b=regs[rt]
            if fn==32:write=(rd,(a+b)&0xffffffff)
            elif fn==34:write=(rd,(a-b)&0xffffffff)
            elif fn==36:write=(rd,a&b)
            elif fn==37:write=(rd,a|b)
            elif fn==42:write=(rd,int(signed(a)<signed(b)))
        elif op==8:write=(rt,(regs[rs]+imm)&0xffffffff)
        elif op==35:write=(rt,mem[((regs[rs]+imm)&0xffffffff)//4])
        elif op==43:mem[((regs[rs]+imm)&0xffffffff)//4]=regs[rt]
        elif op==4:
            if regs[rs]==regs[rt]:npc=pc+1+imm
        elif op==2:npc=x&0x3ffffff
        if write and write[0]:regs[write[0]]=write[1]
        regs[0]=0;pc=npc
    raise RuntimeError('reference program did not terminate')

def schedule(code):
    out=[]
    for pc,x in enumerate(code):
        op=x>>26
        if op==4:
            imm=x&65535
            if imm&32768:imm-=65536
            target=pc+1+imm
            x=(x&0xffff0000)|((target*4-len(out)-1)&65535)
        elif op==2:x=(2<<26)|((x&0x3ffffff)*4)
        out.extend([x,0,0,0])
    return out

def injected(rel,top,name,code,regs,mem,cycles=2000,stall_expect=None,schedule_program=True):
    er,em=reference(code,regs,mem)
    image=schedule(code) if top=='CPU_Pipeline' and schedule_program else code
    setup='\n'.join(f"    uut.IM.memory[{n}]=32'h{x:08x};" for n,x in enumerate(image))
    setup+='\n'+'\n'.join(f"    uut.RF.Regfile[{n}]=32'h{x:08x};" for n,x in enumerate(regs))
    setup+='\n'+'\n'.join(f"    uut.DM.memory[{n}]=32'h{x:08x};" for n,x in enumerate(mem))
    checks='\n'.join(f"    if (uut.RF.Regfile[{n}] !== 32'h{x:08x}) $fatal(1, \"{name} r{n} got %h expected {x:08x}\",uut.RF.Regfile[{n}]);" for n,x in enumerate(er))
    checks+='\n'+'\n'.join(f"    if (uut.DM.memory[{n}] !== 32'h{x:08x}) $fatal(1, \"{name} mem[{n}] mismatch\");" for n,x in enumerate(em))
    stall_code=''
    if stall_expect is not None:
        stall_code='integer stalls=0; always @(posedge CLK) if (!RST && !uut.PCWrite) stalls=stalls+1;'
        checks+=f'\n    if (stalls !== {stall_expect}) $fatal(1,"stall count %0d expected {stall_expect}",stalls);'
    tb=BUILD/(name+'.v')
    tb.write_text(f'''`timescale 1ns / 1ps
module test;
  reg CLK=0,RST=0; always #5 CLK=~CLK;
  {top} uut(.CLK(CLK),.RST(RST));
  {stall_code}
  initial begin
    #1 RST=1; #11 RST=0;
    // Install at a negative-edge-free instant after reset, before first IF edge.
    for (integer n=0;n<1024;n=n+1) uut.IM.memory[n]=0;
{setup}
    repeat ({cycles}) @(negedge CLK);
    #1;
{checks}
    $display("PASS {name}: all 32 registers and 1024 memory words match ISA reference");
    $finish;
  end
endmodule
''',encoding='utf-8')
    run(rel,'test',tb,name)

for rel,top in [('02-final-pj/pipeline','CPU_Pipeline'),('02-final-pj/hazard','CPU_NoHazard'),('03-final-project-rar/pipeline','CPU_Pipeline')]:
    run(rel,top+'_tb',REPO/'sources'/rel/'tb'/(top+'_tb.v'),rel.replace('/','_')+'_demo')
    regs=[0]*32;regs[1]=29;regs[3]=5;regs[5]=0xf;regs[6]=0x100;regs[15]=0x12345678
    mem=[0]*1024
    exact=[inst_r(1,3,2,34),inst_r(2,5,12,36),inst_r(6,2,13,37),inst_r(2,2,14,32),inst_i(43,2,15,100)]
    injected(rel,top,rel.replace('/','_')+'_slide8',exact,regs,mem,cycles=100)
    # Dense wrong paths exercise squash at every younger stage, with no RAW
    # dependencies. A younger ID-stage jump must lose to the MEM-stage branch.
    regs=[0]*32;regs[1]=29;regs[2]=29;regs[3]=0x11223344;regs[30]=400
    controls=[inst_i(4,1,2,4),inst_i(43,30,3,0),inst_i(8,0,10,99),(2<<26)|12,
              inst_i(43,30,3,4),inst_i(4,1,3,1),inst_i(8,0,11,11),(2<<26)|10,
              inst_i(43,30,3,8),inst_i(8,0,12,99),inst_i(8,0,13,13),(2<<26)|13,
              inst_i(43,30,3,12),inst_i(8,0,14,14)]
    injected(rel,top,rel.replace('/','_')+'_dense_control',controls,regs,mem,cycles=100,schedule_program=False)
    # Slide 3/4 loop with 400-byte endpoint, standard MIPS register aliases.
    regs=[0]*32;regs[19]=15;regs[12]=10;regs[11]=3;regs[21]=800
    mem=list(range(1024))
    loop=[inst_i(8,16,9,400),inst_i(35,9,17,0),inst_r(18,17,18,32),inst_i(8,9,9,-4),
          inst_r(9,16,10,42),inst_i(4,10,0,-5),(2<<26)|8,inst_i(8,0,22,99),
          inst_r(19,16,20,37),inst_r(12,11,12,34),inst_r(20,12,13,36),inst_i(43,21,13,0)]
    injected(rel,top,rel.replace('/','_')+'_deck400',loop,regs,mem,cycles=4000)
    for seed in [431,902,1874]:
        rng=random.Random(seed);regs=[rng.getrandbits(32) for _ in range(32)];regs[0]=0;regs[30]=400
        mem=[rng.getrandbits(32) for _ in range(1024)]
        code=[]
        for pc in range(180):
            kind=rng.randrange(10);rs=rng.randrange(21);rt=rng.randrange(21);rd=rng.randrange(21)
            if kind<5: x=inst_r(rs,rt,rd,[32,34,36,37,42][kind])
            elif kind==5:x=inst_i(8,rs,rt,rng.randrange(-32768,32768))
            elif kind==6:x=inst_i(35,30,rt,rng.randrange(-100,101)*4)
            elif kind==7:x=inst_i(43,30,rt,rng.randrange(-100,101)*4)
            elif kind==8:x=inst_i(4,rs,rs if rng.randrange(2) else rt,rng.randrange(1,4))
            else:x=(2<<26)|(pc+1+rng.randrange(1,4))
            code.append(x)
        injected(rel,top,rel.replace('/','_')+f'_random{seed}',code,regs,mem,cycles=1300)

# Hazard-only dependency and stall oracle: two real load-use stalls, zero-register
# and immediate-destination matches must not stall.
regs=[0]*32;regs[30]=400;mem=[0]*1024;mem[100]=13
loaduse=[inst_i(35,30,1,0),inst_r(1,1,2,32),inst_i(35,30,3,0),inst_i(43,30,3,4),
         inst_i(35,30,0,0),inst_i(8,0,4,7),inst_i(35,30,5,0),inst_i(8,0,5,11),
         inst_i(35,30,6,0),inst_i(4,6,1,1),inst_i(8,0,7,99),inst_i(8,0,8,-4)]
injected('02-final-pj/hazard','CPU_NoHazard','hazard_stall_count',loaduse,regs,mem,cycles=150,stall_expect=3)

(BUILD/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
print(f"{sum(r['passed'] for r in results)}/{len(results)} repaired pipeline tests passed.")
raise SystemExit(any(not r['passed'] for r in results))
