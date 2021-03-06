import pandas as pd
import numpy as np
import matplotlib.pylab as plt
import matplotlib
import os
import glob
import multiprocessing as mp
import sys

#        print(f"{c} {b['sys']} {b['itr']} {b['dvfs']} {b['rapl']} {round(b['edp_mean'], 2)} {round(b['edp_std'], 2)} {round(b['joules_mean'], 2)} {int(b['read_99th_mean'])} {int(b['num_interrupts_mean'])} {int(b['instructions_mean'])} {int(b['ref_cycles_mean'])} {int(b['llc_miss_mean'])} {int(b['c1_mean'])} {int(b['c1e_mean'])} {int(b['c3_mean'])} {int(b['c6_mean'])} {int(b['c7_mean'])} {int(csum)} {int(b['rx_bytes_mean'])} {int(b['tx_bytes_mean'])}")
def printSorted(d):
    c=0
    for index, b in d.iterrows():
        csum = int(b['c1_mean'])+int(b['c1e_mean'])+int(b['c3_mean'])+int(b['c6_mean'])+int(b['c7_mean'])
        cpi=round(int(b['ref_cycles_mean'])/int(b['instructions_mean']), 2)
        
        print(f"{c} {b['sys']} {b['itr']} {b['dvfs']} {b['rapl']} {round(b['edp_mean'], 2)} {round(b['edp_std'], 2)} {round(b['joules_mean'], 2)} {round(b['joules_std'], 2)} {int(b['read_99th_mean'])} {int(b['read_99th_std'])} {int(b['num_interrupts_mean'])} {int(b['num_interrupts_std'])} {cpi} {int(b['instructions_mean'])} {int(b['instructions_std'])} {int(b['ref_cycles_mean'])} {int(b['ref_cycles_std'])} {int(b['llc_miss_mean'])} {int(b['llc_miss_std'])} {int(b['c1_mean'])} {int(b['c1_std'])} {int(b['c1e_mean'])} {int(b['c1e_std'])} {int(b['c3_mean'])} {int(b['c3_std'])} {int(b['c6_mean'])} {int(b['c6_std'])} {int(b['c7_mean'])} {int(b['c7_std'])} {int(csum)} {int(b['rx_bytes_mean'])} {int(b['rx_bytes_std'])} {int(b['tx_bytes_mean'])} {int(b['tx_bytes_std'])}")
        c += 1
        if c > 9:
            break
        
#print(len(sys.argv), sys.argv)
if len(sys.argv) != 2:
    print("table.py <QPS>")
    exit()
QPS = int(sys.argv[1])

JOULE_CONVERSION = 0.00001526 #counter * constant -> JoulesOB
TIME_CONVERSION_khz = 1./(2899999*1000)

#workload_loc='/scratch2/mcd/mcd_top10/mcd_combined.csv'
workload_loc='/scratch2/mcd/mcd_combined_11_9_2020/mcd_combined.csv'

df = pd.read_csv(workload_loc, sep=' ')
df = df[df['joules'] > 0]
df = df[df['read_99th'] <= 500.0]
df = df[df['target_QPS'] == QPS]
df['edp'] = df['joules'] * df['read_99th']
#df['edp'] = df['joules']

NCOLS = ['sys', 'itr', 'dvfs', 'rapl']
df_mean = df.groupby(NCOLS).mean()
df_std = df.groupby(NCOLS).std()

df_mean.columns = [f'{c}_mean' for c in df_mean.columns]
df_std.columns = [f'{c}_std' for c in df_std.columns]

df_comb = pd.concat([df_mean, df_std], axis=1)
df_comb.reset_index(inplace=True)
df_comb = df_comb.fillna(0) ## dangerous

#d = df_comb[(df_comb['sys']=='linux_default') & (df_comb['itr']==1) & (df_comb['dvfs']=='0xffff')].copy()
#printSorted(d.sort_values(by='edp_mean', ascending=True).copy())

#d = df_comb[(df_comb['sys']=='linux_tuned') & (df_comb['itr']!=1) & (df_comb['dvfs']!='0xffff')].copy()
#printSorted(d.sort_values(by='edp_mean', ascending=True).copy())

d = df_comb[(df_comb['sys']=='ebbrt_tuned') & (df_comb['itr']!=1) & (df_comb['dvfs']!='0xffff')].copy()
printSorted(d.sort_values(by='edp_mean', ascending=True).copy())


'''

dld = df[(df['sys']=='linux_default') & (df['itr']==1) & (df['dvfs']=='0xffff') & (df['target_QPS'] == QPS)].copy()
dlt = df[(df['sys']=='linux_tuned') & (df['target_QPS'] == QPS)].copy()
det = df[(df['sys']=='ebbrt_tuned') & (df['target_QPS'] == QPS)].copy()


bconf={}
wconf={}
for dbest in [dld, dlt, det]:
    b = dbest[dbest.edp==dbest.edp.min()].iloc[0]
    bconf[b['sys']] = [b['i'], b['itr'], b['dvfs'], b['rapl']]
    w = dbest[dbest.edp==dbest.edp.max()].iloc[0]
    wconf[w['sys']] = [w['i'], w['itr'], w['dvfs'], w['rapl']]

for dsys in ['linux_default', 'linux_tuned', 'ebbrt_tuned']:
    num = bconf[dsys][0]
    itr = bconf[dsys][1]
    dvfs = bconf[dsys][2]
    rapl = bconf[dsys][3]
    d = df[(df['sys']==dsys) & (df['itr']==itr) & (df['dvfs']==dvfs) & (df['rapl']==rapl) & (df['target_QPS'] == QPS)].copy()
    #print(d)
    if dsys == 'linux_tuned':
        print(d)
    edp_mean = d['edp'].mean()
    edp_std = d['edp'].std()
    joules_mean = d['joules'].mean()
    read_99th_mean = d['read_99th'].mean()    
    print(f"best epp {QPS} {dsys} {itr},{dvfs},{rapl} {round(edp_mean, 3)} {round(edp_std, 3)} {round(joules_mean, 3)} {round(read_99th_mean, 3)}")

for dsys in ['linux_default', 'linux_tuned', 'ebbrt_tuned']:
    num = wconf[dsys][0]
    itr = wconf[dsys][1]
    dvfs = wconf[dsys][2]
    rapl = wconf[dsys][3]
    d = df[(df['sys']==dsys) & (df['itr']==itr) & (df['dvfs']==dvfs) & (df['rapl']==rapl) & (df['target_QPS'] == QPS)].copy()
    #print(d)
    edp_mean = d['edp'].mean()
    edp_std = d['edp'].std()
    joules_mean = d['joules'].mean()
    read_99th_mean = d['read_99th'].mean()    
    print(f"worst epp {QPS} {dsys} {itr},{dvfs},{rapl} {round(edp_mean, 3)} {round(edp_std, 3)} {round(joules_mean, 3)} {round(read_99th_mean, 3)}")
'''
    
'''
for d in [dld, dlt, det]:
    for m in [200000, 400000, 600000]:
        dbest = d[d['target_QPS'] == m].copy()
        dbest['edp'] = dbest['joules'] * dbest['read_99th']
        b = dbest[dbest.edp==dbest.edp.min()].iloc[0] 
        print('Best EPP', m)
        ins="{:e}".format(b['instructions'])
        rcyc="{:e}".format(b['ref_cycles'])
        rb="{:e}".format(b['rx_bytes'])
        tb="{:e}".format(b['tx_bytes'])
        numi="{:e}".format(b['num_interrupts'])
        print(f"{b['sys']} {b['itr']},{b['dvfs']},{b['rapl']} {round(b['edp'], 3)} {round(b['read_99th'],3)} {ins} {rcyc} {rb} {tb} {numi}")
        
        b = dbest[dbest.joules==dbest.joules.min()].iloc[0] 
        print('Best Joules', m)
        ins="{:e}".format(b['instructions'])
        rcyc="{:e}".format(b['ref_cycles'])
        rb="{:e}".format(b['rx_bytes'])
        tb="{:e}".format(b['tx_bytes'])
        numi="{:e}".format(b['num_interrupts'])
        print(f"{b['sys']} {b['itr']},{b['dvfs']},{b['rapl']} {round(b['joules'],3)} {round(b['read_99th'],3)} {ins} {rcyc} {rb} {tb} {numi}")
        
        b = dbest[dbest.read_99th==dbest.read_99th.min()].iloc[0]
        print('Best Tail', m)
        ins="{:e}".format(b['instructions'])
        rcyc="{:e}".format(b['ref_cycles'])
        rb="{:e}".format(b['rx_bytes'])
        tb="{:e}".format(b['tx_bytes'])
        numi="{:e}".format(b['num_interrupts'])
        print(f"{b['sys']} {b['itr']},{b['dvfs']},{b['rapl']} {round(b['joules'], 3)} {round(b['read_99th'],3)} {ins} {rcyc} {rb} {tb} {numi}") 
'''
