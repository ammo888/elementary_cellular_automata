import os
import json
from web3 import Web3
from pathlib import Path
from dotenv import load_dotenv
import streamlit as st
from urllib.request import urlopen

load_dotenv()

w3 = Web3(Web3.HTTPProvider(os.getenv("WEB_PROVIDER_URI")))

@st.cache(allow_output_mutation=True)
def load_contract():
    with open(Path("abi.json")) as abi:
        artwork_abi = json.load(abi)

    artwork_address = os.getenv("CONTRACT_ADDRESS")
    contract = w3.eth.contract(address=artwork_address, abi=artwork_abi)
    return contract

contract = load_contract()

st.title('Elementary Cellular Automaton')

accounts = w3.eth.accounts

min_price_wei = contract.functions.BASE_PRICE().call()
min_price_ether = Web3.fromWei(min_price_wei, 'ether')

address = st.selectbox("Select address", options=accounts)
rule = st.number_input("Automata rule", min_value=0, max_value=255)
state = st.number_input("Initial state", min_value=0)
size_type = st.number_input("Size type", min_value=1, max_value=5)
payment = st.number_input("Payment (ether)", min_value=float(min_price_ether * size_type * size_type))

if st.button("Generate artwork"):
    draw_size = (1 << size_type) - 1
    state_mask = (1 << draw_size) - 1
    state_format = f"0{draw_size}b"
    st.write(f"Generating rule {rule} state {format(state & state_mask, state_format)}")
    tx_hash = contract.functions.createCellularAutomaton(rule, state, size_type).transact({"from": address, "value": Web3.toWei(payment, 'ether')})
    receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    st.write("Receipt is ready: ")
    st.write(dict(receipt))

if st.button("Draw"):
    draw_size = (1 << size_type) - 1
    state_mask = (1 << draw_size) - 1
    token_id = ((state & state_mask) << 16) | (rule << 8) | size_type
    st.write(f"Drawing {token_id}")
    token_uri = contract.functions.tokenURI(token_id).call()

    with urlopen(token_uri) as response:
        data = response.read()
        s = data.decode('utf-8')
        st.code(s)
