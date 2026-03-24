# DynamicTaxToken

A SIP-010 compliant fungible token with volatility-based dynamic transfer taxation on the Stacks blockchain.

## Overview

DynamicTaxToken (DYN-TOKEN) is a smart contract that implements a fungible token with an adaptive transfer tax system. The tax rate automatically adjusts between a stable mode (0.1%) and a volatile mode (1%), allowing protocol treasuries to collect fees flexibly based on market conditions.

## Features

- **Dynamic Tax Rates**: Switch between 0.1% (stable) and 1% (volatile) modes
- **SIP-010 Compliance**: Implements standard fungible token interface with ft-* helpers
- **Flexible Revenue Model**: Treasury collects fees from every taxed transfer
- **Admin Controls**: Set treasury address, toggle volatility mode, mint/burn tokens
- **Precise Calculations**: Floor-based fee computation prevents rounding errors
- **Error Handling**: Comprehensive error codes for debugging and validation

## Contract Specifications

### Token Details
- **Token Name**: DYN-TOKEN
- **Standard**: SIP-010 (Fungible Token Standard)
- **Decimals**: 6 (default)

### Tax Rates
- **Stable Mode**: 1/1000 = 0.1%
- **Volatile Mode**: 10/1000 = 1.0%

### Taxed Transfer Example
