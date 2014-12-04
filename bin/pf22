#!/bin/bash

main(){
	local SSHOPT="-gCN"
	local USER="sho"
	local HOST="localhost"
	local PORT_LOCAL="1417"
	local PORT_OPEN="22"
	local KEY="/root/.ssh/id_rsa.local"
	echo ssh -i ${KEY} -l ${USER} -p ${PORT_LOCAL} ${SSHOPT} ${HOST} -L ${PORT_OPEN}:${HOST}:${PORT_LOCAL}
	ssh -i ${KEY} -l ${USER} -p ${PORT_LOCAL} ${SSHOPT} ${HOST} -L ${PORT_OPEN}:${HOST}:${PORT_LOCAL}
}

main
