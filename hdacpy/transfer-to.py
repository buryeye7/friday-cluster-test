#!/usr/bin/python3

import datetime
from hdacpy.wallet import generate_wallet
from hdacpy.transaction import Transaction
import time
import sys

host="http://" + sys.argv[1] + ":1317"
privkey=sys.argv[2]
print("host " + host)
print("privkey " + privkey)

diffList=[]
fd=open("./diffs/diff_" + privkey +".txt","w")
for i in range(10000):
        print("count", i)
        amount = (i+1)%100
        try:
            tx = Transaction(
                    host=host,
                    privkey=privkey,
                    chain_id="testnet",
                    sequence=i
                )
            startTime = datetime.datetime.now().timestamp()
            tx.transfer(
                    recipient_address="friday19ktfw6flujxvxfnpgvldn4wj5mdx0565g6n4cj7zgshcfaxsyudsd9248t",
                    amount=amount, gas_price=30000000, fee=1
            )
            endTime = datetime.datetime.now().timestamp()
            diff = endTime - startTime
            #fd.write(str(diff)+"\n")
            diffList.append(str(diff) + "\n")
        except:
            print("exception happened", sys.exc_info()[0])

for diff in diffList:
    fd.write(diff)
fd.close()
