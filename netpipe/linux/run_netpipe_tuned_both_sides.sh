set -x
# MSGSIZES='1000 4096 8192 16384 24576 65536 98304 131072 262144 393216 524288' ITR='2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72 74 76 78 80 82 84 86 88 90 100 200 300' MDVFS='0x1900' MRAPL='135' REPEAT=1 WRITEBACK_DIR="/mnt/netpipe/linux/10_14/" ROLE="CLIENT" MYIP="192.168.1.11" NP_SERVER_IP="192.168.1.9" SCREEN_PRESLEEP=60 ./run_netpipe_tuned.sh
#MSGSIZES='64 128 256 512 1434 1440 1448 1449 1450 1500' ITR='2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 34 38 42 46 50 54 58 62 66 70 74 78 82 86 90 94 100 140 180 260' MDVFS='0x1900' MRAPL='135' REPEAT=2 WRITEBACK_DIR="/mnt/netpipe/linux/10_6" MYIP="192.168.1.9" CAPSHARK=1 SCREEN_PRESLEEP=60 ./run_netpipe_tuned.sh
#MSGSIZES='64 128 256 512 1434 1440 1448 1449 1450 1500' ITR='2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 34 38 42 46 50 54 58 62 66 70 74 78 82 86 90 94 100 140 180 260' MDVFS='0x1900' MRAPL='135' REPEAT=2 WRITEBACK_DIR="/mnt/netpipe/linux/10_6" ROLE="CLIENT" MYIP="192.168.1.11" NP_SERVER_IP="192.168.1.9" SCREEN_PRESLEEP=60 ./run_netpipe_tuned.sh

#example server: MSGSIZES='8192' ITR='8 4' MDVFS='0x1d00 0x1c00' MRAPL='135' REPEAT=1 WRITEBACK_DIR="/mnt/netpipe/linux/9_27" MYIP="192.168.1.9" ./run_netpipe_tuned.sh
#example client: MSGSIZES='8192' ITR='8 4' MDVFS='0x1d00 0x1c00' MRAPL='135' REPEAT=1 WRITEBACK_DIR="/mnt/netpipe/linux/9_27" ROLE="CLIENT" MYIP="192.168.1.11" NP_SERVER_IP="192.168.1.9" ./run_netpipe_tuned.sh
# tshark -i eth0 -w t.pcap -F pcap host 192.168.1.9 &

ts=$(date +"%m.%d.%y-%H.%M.%S")

INSMOD=insmod
RMMOD=rmmod
IP=ip
TASKSET=taskset
DMESG=dmesg
CAT=cat
SLEEP=sleep
IXGBE=ixgbe
RDMSR=rdmsr
WRMSR=wrmsr
SSH=ssh
SCP=scp
TSHARK=tshark
PKILL=pkill
RM=rm
ETHTOOL=/app/ethtool-4.5/ethtool
SETAFFINITY=/app/perf/set_irq_affinity_ixgbe.sh
DISABLE_HT=/app/perf/disable_ht.sh
ENABLE_IDLE=/app/perf/enable_cstates.sh
MSR_MAX_FREQ=/app/perf/msr_max_freq.sh
NETPIPE=/app/NetPIPE-3.7.1/NPtcp_joules
RAPL_POW_MOD=/app/uarch-configure/rapl-read/rapl-power-mod
ETHMODULE_NOLOG=/app/ixgbe/ixgbe_orig.ko
ETHMODULE_YESLOG=/app/ixgbe/ixgbe_log.ko
SET_IP=/app/perf/set_ip.sh
IXGBE_STATS_CORE=/proc/ixgbe_stats/core
DVFS="0x199"
TURBOBOOST="0x1a0"

export ROLE=${ROLE:-"SERVER"}
export DEVICE=${DEVICE:-"eth0"}
export MYIP=${MYIP:-"192.168.1.9"}
export NP_SERVER_IP=${NP_SERVER_IP:-"192.168.1.9"}
export HOST_IP=${HOST_IP:-"192.168.1.153"}
#export ITR=${ITR:-"0 4 8 12 16 20 24 28 32 36 40 60 80 100"}
export ITR=${ITR:-"10"}
#export MSGSIZES=${MSGSIZES:-"64 128 256 512 1024 2048 3072 4096 8192 12288 16384 24576 49152 65536 98304 131072 196608 262144 393216 524288 786432"}
export MSGSIZES=${MSGSIZES:-"64 8192 65536 524288"}
export LOOP=${LOOP:-"5000"}
export TASKSETCPU=${TASKSETCPU:-"1"}
#export MDVFS=${MDVFS:="0x1d00 0x1c00 0x1b00 0x1a00 0x1900 0x1800 0x1700 0x1600 0x1500 0x1400 0x1300 0x1200 0x1100 0x1000 0xf00 0xe00 0xd00 0xc00"}
export MDVFS=${MDVFS:="0x1d00"}
export MRAPL=${MRAPL:-"135"}
export REPEAT=${REPEAT:-1}
export BEGINI=${BEGINI:-0}
export PERF_INIT=${PERF_INIT:-0}
export CAPSHARK=${CAPSHARK:-0}
export WRITEBACK_DIR=${WRITEBACK_DIR:-"/tmp/"}
export SCREEN_PRESLEEP=${SCREEN_PRESLEEP:-1}

echo "Sleeping ${SCREEN_PRESLEEP} seconds for screen"
sleep ${SCREEN_PRESLEEP}

if [[ ${PERF_INIT} == 1 ]]; then
    ## apply performance scripts
    ${DISABLE_HT}
    ${SLEEP} 1
    ${ENABLE_IDLE}
    ${SLEEP} 1
    ${MSR_MAX_FREQ}
    ${SLEEP} 1
    ${RAPL_POW_MOD} 135
    ${SLEEP} 1

    ## apply ixgbe module with logging
    #if [[ ${ROLE} == "SERVER" ]]; then    
    ${SLEEP} 1
    ${RMMOD} ${IXGBE} && ${INSMOD} ${ETHMODULE_YESLOG} && ${SET_IP} ${DEVICE} ${MYIP}
    ${SLEEP} 1
    #fi

    ## set ITR to statically tuned
    ${ETHTOOL} -C ${DEVICE} rx-usecs 10
    ${SLEEP} 1
    ${IP} link set ${DEVICE} down && ${IP} link set ${DEVICE} up
    ${SLEEP} 1
fi

## dump results from setting PERF_INIT
${SETAFFINITY} -x all ${DEVICE}
${ETHTOOL} -c ${DEVICE}
${SLEEP} 1
${RDMSR} -a ${DVFS}
${RDMSR} -a ${TURBOBOOST}

for ((i=$BEGINI;i<$REPEAT; i++)); do
    for msg in $MSGSIZES; do
    	for itr in $ITR; do
	    #echo "${ETHTOOL} -C ${DEVICE} rx-usecs ${itr}"
	    ${ETHTOOL} -C ${DEVICE} rx-usecs ${itr}
	    for dvfs in ${MDVFS}; do
	    	if [[ ${ROLE} == "SERVER" ]]; then
		    ${WRMSR} -p ${TASKSETCPU} ${DVFS} ${dvfs}
		    #echo "${WRMSR} -p ${TASKSETCPU} ${DVFS} ${dvfs}"
		    ${SLEEP} 1
		fi
	    	
	    	for r in ${MRAPL}; do
		    if [[ ${ROLE} == "SERVER" ]]; then
			#echo "${RAPL_POW_MOD} ${r}"
			${RAPL_POW_MOD} ${r}
			${SLEEP} 1
		    fi
		    
		    if [[ ${ROLE} == "SERVER" ]]; then
			## clean up previous trace logs just incase
			${CAT} ${IXGBE_STATS_CORE}/${TASKSETCPU} &> /dev/null

			## start wireshark
			if [[ ${CAPSHARK} == 1 ]]; then
			    ${SLEEP} 1
			    ${TASKSET} -c 0 ${TSHARK} -i ${DEVICE} -w /app/tshark.server.pcap.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r} -F pcap host ${MYIP} &
			    ${SLEEP} 1
			fi

			## start np server
		        ${TASKSET} -c ${TASKSETCPU} ${NETPIPE} -l ${msg} -u ${msg} -n ${LOOP} -p 0 -r -I &> /app/linux.np.server.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}

			if [[ ${CAPSHARK} == 1 ]]; then
			    ${SLEEP} 1
			    ${PKILL} ${TSHARK}
			    ${SLEEP} 1
			fi			
			
			# dumps logs
			${CAT} ${IXGBE_STATS_CORE}/${TASKSETCPU} &> /app/linux.np.server.log.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}
			${SLEEP} 5
		    else
			## start wireshark
			if [[ ${CAPSHARK} == 1 ]]; then
			    ${SLEEP} 1
			    ${TASKSET} -c 0 ${TSHARK} -i ${DEVICE} -w /app/tshark.client.pcap.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r} -F pcap host ${MYIP} &
			    ${SLEEP} 1
			fi

			
			#echo "CLIENT"
		        while ! ${TASKSET} -c ${TASKSETCPU} ${NETPIPE} -h ${NP_SERVER_IP} -l ${msg} -u ${msg} -n ${LOOP} -p 0 -r -I; do
			    echo "FAILED: Server not ready trying again ..."
			    ${SLEEP} 5
			    ## clean up previous trace logs just incase
			    ${CAT} ${IXGBE_STATS_CORE}/${TASKSETCPU} &> /dev/null
			done

			if [[ ${CAPSHARK} == 1 ]]; then
			    ${SLEEP} 1
			    ${PKILL} ${TSHARK}
			    ${SLEEP} 1
			fi			
			
			# dumps logs
			${CAT} ${IXGBE_STATS_CORE}/${TASKSETCPU} &> /app/linux.np.client.log.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}
			${SLEEP} 1
			
		        ${CAT} np.out &> /app/linux.np.client.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}
			${SLEEP} 5
		    fi

		    # copy data to HOST_IP
		    ${SLEEP} 1
		    ${SCP} /app/*.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r} ${HOST_IP}:${WRITEBACK_DIR}/
		    ${SLEEP} 1
	    	    ${RM} /app/*.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}
		    if [[ ${ROLE} == "SERVER" ]]; then
			ssh 192.168.1.153 cp /root/github/tcp/rdtscs.log.0_${msg} ${WRITEBACK_DIR}/rdtscs.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}
		    fi		    
	        done
	    done
        done	
    done
done
