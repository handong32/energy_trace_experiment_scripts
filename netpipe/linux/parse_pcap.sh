set -x
# tshark -i eth0 -w t.pcap -F pcap host 192.168.1.9 &
#
TSHARK=tshark
TSHARK_OPTIONS='-T fields -E separator=, -e frame.number -e frame.time_epoch -e frame.time_delta_displayed -e ip.src -e ip.dst -e tcp.port -e frame.cap_len -e tcp.window_size -e tcp.analysis.fast_retransmission -e tcp.analysis.retransmission'

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
export WRITEBACK_DIR=${WRITEBACK_DIR:-"./"}

for ((i=$BEGINI;i<$REPEAT; i++)); do
    for msg in $MSGSIZES; do
    	for itr in $ITR; do
	    for dvfs in ${MDVFS}; do
	    	for r in ${MRAPL}; do
		    if [ -f "${WRITEBACK_DIR}/tshark.pcap.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}" ]; then
			${TSHARK} -r ${WRITEBACK_DIR}/tshark.pcap.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r} ${TSHARK_OPTIONS} > ${WRITEBACK_DIR}/tshark.pcap.${i}_${TASKSETCPU}_${msg}_${LOOP}_${itr}_${dvfs}_${r}.csv
		    fi
	        done
            done
        done	
    done
done
