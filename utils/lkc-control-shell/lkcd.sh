#!/bin/sh

# Copyright (c) 2016-2018, luckycoin developers (Aiwe, Lastick)
# English correction by Grabbers
#
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
#    conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
#    of conditions and the following disclaimer in the documentation and/or other
#    materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be
#    used to endorse or promote products derived from this software without specific
#    prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


DATA_DIR="/var/luckycoin"
LOG_DIR="/var/log/luckycoin"
RUN_DIR="/var/run/luckycoin"
TMP_DIR="/tmp"
HTDOCS_DIR="/tmp"

LKCD="/usr/sbin/luckycoind"

LKCD_P2P_IP="0.0.0.0"
LKCD_P2P_PORT="32347"
LKCD_RPC_IP="127.0.0.1"
LKCD_RPC_PORT="32348"
LKCD_RPC_SSL_PORT="32448"
LKCD_RPC_CHAIN_PATH="/var/luckycoin/rpc_server.crt"
LKCD_RPC_KEY_PATH="/var/luckycoin/rpc_server.key"
LKCD_LOG_LEVEL="2"
LKCD_FEE_ADDRESS="Ke5tURH8PotZfvk3B444EtEu29PwtjTND4SBmw1NL7gd9gZ6y78F9cz4ZKepay2o2uH4HXu4poTUeJ4FyQMiaTukLKgrpLS"
LKCD_FEE_AMOUNT="0.1"
LKCD_VIEW_KEY=""

KRBS_CONTROL="/usr/lib/luckycoin/krbs.sh"

SIGTERM_TIMEOUT=240
SIGKILL_TIMEOUT=120

ZIP="/usr/bin/zip"


## Base check

# Check all work directories
if [ -d $DATA_DIR ]; then
  if [ ! -w $DATA_DIR ]; then
    echo "Error: DATA dir not writable!"
    exit 1
  fi
else
  echo "Error: DATA dir not found!"
  exit 1
fi

if [ -d $LOG_DIR ]; then
  if [ ! -w $LOG_DIR ]; then
    echo "Error: LOG dir not writable!"
    exit 1
  fi
else
  echo "Error: LOG dir not found!"
  exit 1
fi

if [ -d $RUN_DIR ]; then
  if [ ! -w $RUN_DIR ]; then
    echo "Error: RUN dir not writable!"
    exit 1
  fi
else
  echo "Error: RUN dir not found!"
  exit 1
fi

if [ -d $TMP_DIR ]; then
  if [ ! -w $TMP_DIR ]; then
    echo "Error: TMP dir not writable!"
    exit 1
  fi
else
  echo "Error: TMP dir not found!"
  exit 1
fi

if [ -d $HTDOCS_DIR ]; then
  if [ ! -w $HTDOCS_DIR ]; then
    echo "Error: HTDOCS dir not writable!"
    exit 1
  fi
else
  echo "Error: HTDOCS dir not found!"
  exit 1
fi

# Check all files
if [ ! -f $LKCD ]; then
  echo "Error: DEAMON bin file not found!"
  exit 1
fi

if [ ! -f $ZIP ]; then
  echo "Error: ZIP archiver bin file not found!"
  exit 1
fi

if [ ! -f $KRBS_CONTROL ]; then
  echo "Error: KRBS start script file not found!"
  exit 1
fi



# Function logger
logger(){
  if [ ! -f $LOG_DIR/LKCD_control.log ]; then
    touch $LOG_DIR/LKCD_control.log
  fi
  mess=[$(date '+%Y-%m-%d %H:%M:%S')]" "$1
  echo $mess >> $LOG_DIR/LKCD_control.log
  echo $mess
}

# Funstion locker
locker(){
  if [ "$1" = "check" ]; then
    if [ -f $RUN_DIR/LKCD_control.lock ]; then
      logger "LOCKER: previous task is not completed; exiting..."
      exit 0
    fi
  fi
  if [ "$1" = "init" ]; then
    touch $RUN_DIR/LKCD_control.lock
  fi
    if [ "$1" = "end" ]; then
    rm -f $RUN_DIR/LKCD_control.lock
  fi
}

# Function init service
service_init(){
  $LKCD --data-dir $DATA_DIR \
        --log-file $LOG_DIR/LKCD.log \
        --log-level $LKCD_LOG_LEVEL \
        --restricted-rpc \
        --no-console \
        --enable-cors "*" \
        --p2p-bind-ip $LKCD_P2P_IP \
        --p2p-bind-port $LKCD_P2P_PORT \
        --rpc-bind-ip $LKCD_RPC_IP \
        --rpc-bind-port $LKCD_RPC_PORT \
        --rpc-bind-ssl-enable \
        --rpc-bind-ssl-port $LKCD_RPC_SSL_PORT \
        --rpc-chain-file $LKCD_RPC_CHAIN_PATH \
        --rpc-key-file $LKCD_RPC_KEY_PATH \
        --fee-address $LKCD_FEE_ADDRESS \
        --fee-amount $LKCD_FEE_AMOUNT \
        --view-key $LKCD_VIEW_KEY > /dev/null & echo $! > $RUN_DIR/LKCD.pid
}

# Function is ready
service_is_ready(){
  sleep 5
  for i in $(seq 1 30); do
    if [ -f $RUN_DIR/LKCD.pid ]; then
      pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
      cpu_load=$(top -b -n 1 -d 1 -p $pid | grep $pid | sed 's/^\s//g' | sed 's/\s\+/\n/g' | sed -n 9p | sed 's/[^0-9,.]*//g' | sed 's/[,|.].*//g')
      logger "-> Node load CPU: "$cpu_load
      if [ "$cpu_load" -lt 5 ]; then
        break
      fi
    fi
    sleep 3
  done
}

# Function start service
service_start(){
  if [ ! -f $RUN_DIR/LKCD.pid ]; then
    logger "START: trying to start service..."
    service_init
    sleep 5
    if [ -f $RUN_DIR/LKCD.pid ]; then
      pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
      if [ -f /proc/$pid/stat ]; then
        logger "START: success!"
      fi
    fi
  else
    pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
    if [ -f /proc/$pid/stat ]; then
      logger "START: process is already running"
    else
      logger "START: abnormal termination detected; starting..."
      rm -f $RUN_DIR/LKCD.pid
      service_init
      sleep 5
      if [ -f $RUN_DIR/LKCD.pid ]; then
        pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
        if [ -f /proc/$pid/stat ]; then
          logger "START: success!"
        fi
      fi
    fi
  fi
}

# Function stop service
service_stop(){
  if [ -f $RUN_DIR/LKCD.pid ]; then
    logger "STOP: attempting to stop the service..."
    pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
    if [ -f /proc/$pid/stat ]; then
      kill $pid
      sleep 5
      for i in $(seq 1 $SIGTERM_TIMEOUT); do
        if [ ! -f /proc/$pid/stat ]; then
          rm -f $RUN_DIR/LKCD.pid
          logger "STOP: success!"
          break
        fi
        sleep 1
      done
      if [ -f $RUN_DIR/LKCD.pid ]; then
        logger "STOP: attempt failed, trying again..."
        kill -9 $pid
        sleep 5
        for i in $(seq 1 $SIGKILL_TIMEOUT); do
          if [ ! -f /proc/$pid/stat ]; then
            rm -f $RUN_DIR/LKCD.pid
            logger "STOP: service has been killed (SIGKILL) due to ERROR!"
            break
          fi
          sleep 1
        done
      fi
    else
      logger "STOP: PID file found, but service not detected; possible error..."
      rm -f $RUN_DIR/LKCD.pid
    fi
  else
    logger "STOP: no service found!"
  fi
}

# Function archiver blockchain
archiver(){
  logger "ARCHIVER: began"
  if [ -f $DATA_DIR/blocks.dat ] && [ -f $DATA_DIR/blockindexes.dat ]; then
    cd $TMP_DIR
    if [ -d blockchain ]; then
      rm -rf -f blockchain
    fi
    mkdir blockchain
    logger "ARCHIVER: copying target files..."
    cp $DATA_DIR/blocks.dat blockchain/blocks.dat
    cp $DATA_DIR/blockindexes.dat blockchain/blockindexes.dat
    logger "ARCHIVER: packing target files..."
    $ZIP -r blockchain.zip blockchain
    logger "ARCHIVER: calculating md5sum..."
    md5sum blockchain.zip >> blockchain.txt
    rm -rf -f blockchain
    if [ -f $HTDOCS_DIR/blockchain.zip ]; then
      rm -f $HTDOCS_DIR/blockchain.zip
    fi
    if [ -f $HTDOCS_DIR/blockchain.txt ]; then
      rm -f $HTDOCS_DIR/blockchain.txt
    fi
    mv blockchain.zip $HTDOCS_DIR/blockchain.zip
    mv blockchain.txt $HTDOCS_DIR/blockchain.txt
    logger "ARCHIVER: finished!"
  else
    logger "ARCHIVER: error, target files not found!"
  fi
}

# Function checker
checker(){
  logger "CHECKER: began"
  if [ -f $RUN_DIR/LKCD.pid ]; then
    pid=$(sed 's/[^0-9]*//g' $RUN_DIR/LKCD.pid)
    if [ -f /proc/$pid/stat ]; then
      logger "CHECKER: all fine!"
    else
      logger "CHECKER: abnormal termination detected; restarting..."
      do_restart
    fi
    logger "CHECKER: finished!"
  else
    logger "CHECKER: target service not found"
  fi
}

# Fucntion check simplewallet is was started
IS_KRBS="stop"
is_run_simplewallet(){
  if [ -f $RUN_DIR/KRBS.pid ]; then
    IS_KRBS="run"
  fi
}


do_start(){
  logger "DO START: procedure initializing..."
  service_start
  logger "DO START: ok"
}

do_stop(){
  is_run_simplewallet
  logger "DO STOP: procedure initializing..."
  if [ "$IS_KRBS" = "run" ]; then
    logger "DO STOP: stopping dependant service..."
    $KRBS_CONTROL --stop > /dev/null
  fi
  service_stop
  logger "DO STOP: ok"
}

do_restart(){
  is_run_simplewallet
  logger "DO RESTART: procedure initializing..."
  if [ "$IS_KRBS" = "run" ]; then
    logger "DO RESTART: Simplewallet was started and will be stopped. Stopping Simplewallet service..."
    $KRBS_CONTROL --stop > /dev/null
  fi
  service_stop
  service_start
  if [ "$IS_KRBS" = "run" ]; then
    logger "DO RESTART: Simplewallet will be started again. Waiting for the node to be ready..."
    service_is_ready
    logger "DO RESTART: starting Simplewallet service..."
    $KRBS_CONTROL --start > /dev/null
  fi
  logger "DO RESTART: ok"
}

do_check(){
  logger "DO CHECK: procedure initializing..."
  checker
  logger "DO CHECK: ok"
}

do_archiver(){
  logger "DO ARCHIVER: procedure initializing..."
  service_stop
  archiver
  service_start
  logger "DO ARCHIVER: ok"
}


# Command selector
locker "check"
locker "init"

case "$1" in
  "--start")
  do_start
  ;;
  "--stop")
  do_stop
  ;;
  "--restart")
  do_restart
  ;;
  "--check")
  do_check
  ;;
  "--archive")
  do_archiver
  ;;
  *)
  logger "SELECTOR: unknown command"
  ;;
esac

locker "end"
