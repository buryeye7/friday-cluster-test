#!/usr/bin/python3

import threading
import datetime
from hdacpy.wallet import generate_wallet
from hdacpy.transaction import Transaction
import time
import sys

host="http://" + sys.argv[1] + ":1317"
privkey=sys.argv[2]
print("host " + host)
print("privkey " + privkey)

test_number = 7200
interval = 0
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
    except:
        print("exception happened", sys.exc_info()[0])
        threading.Timer(interval, function, [sequence]).start()

function(3600)
#for i in range(10000):
#    sequence = i
#    amount = (i + 1)%100
#    threading.Timer(i, function, [sequence,amount,i]).start()
