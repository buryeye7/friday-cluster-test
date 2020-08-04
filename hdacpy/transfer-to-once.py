#!/usr/bin/python3

import datetime
from hdacpy.wallet import generate_wallet
from hdacpy.transaction import Transaction
import time
import sys

host="http://a5748339ea56511eaa58d0225bf94e82-1408610120.ap-northeast-2.elb.amazonaws.com:1317"
privkey="0081ef89529ce1950be66d56f706414918c9c4051f5c4c5c162ec1aca6984dc9"
amount=1

tx = Transaction(
        host=host,
        privkey=privkey,
        chain_id="testnet",
        sequence=0
    )
tx.transfer(
        recipient_address="friday19ktfw6flujxvxfnpgvldn4wj5mdx0565g6n4cj7zgshcfaxsyudsd9248t",
        amount=amount, gas_price=30000000, fee=1
)
