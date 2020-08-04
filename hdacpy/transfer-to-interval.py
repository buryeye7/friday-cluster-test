#!/usr/bin/python3

import threading
import datetime
from hdacpy.wallet import generate_wallet
from hdacpy.transaction import Transaction
import time
import sys
#import logging
#import logging.handlers


#log = logging.getLogger(__name__)
#fileHandler = logging.FileHandler('./exception.txt', mode='w')
#log.addHandler(fileHandler)

host="http://" + sys.argv[1] + ":1317"
privkey=sys.argv[2]
print("host " + host)
print("privkey " + privkey)

test_number = 3600*24
interval = 1
def function(sequence):
    global interval, test_number
    if sequence == test_number:
        return
    try:
        amount = (sequence + 1)%100
        print("sequence:", sequence)
        print(datetime.datetime.now())
        tx = Transaction(
                host=host,
                privkey=privkey,
                chain_id="testnet",
                sequence=sequence
            )
        tx.transfer(
            recipient_address="friday19ktfw6flujxvxfnpgvldn4wj5mdx0565g6n4cj7zgshcfaxsyudsd9248t",
            amount=amount, gas_price=30000000, fee=1
        )
        threading.Timer(interval, function, [sequence + 1]).start()
    except Exception as e:
        print("exception happened", sys.exc_info()[0])
        print("exception:",str(e))
        #logging.exception("message")
        #traceback.print_exc()
        threading.Timer(interval, function, [sequence]).start()

function(0)
#for i in range(10000):
#    sequence = i
#    amount = (i + 1)%100
#    threading.Timer(i, function, [sequence,amount,i]).start()
