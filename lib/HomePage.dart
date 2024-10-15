import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ReownAppKitModal? _appKitModal;
  String walletAddress = 'No Address';
  String _balance = '0';
  bool isLoading = false;

  // Define the custom network for Sepolia
  final customNetwork = ReownAppKitModalNetworkInfo(
    name: 'Sepolia',
    chainId: '11155111', // Sepolia chain ID
    currency: 'ETH',
    rpcUrl: 'https://rpc.sepolia.org/', // Sepolia RPC URL
    explorerUrl: 'https://sepolia.etherscan.io/', // Explorer URL for Sepolia
    isTestNetwork: true, // Set to true for test networks
  );

  final Set<String> featuredWalletIds = {
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
    '4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0', // Trust Wallet
    'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Coinbase Wallet
    'cbc11415130d01316513f735eac34fd1ad7a5d40a993bbb6772d2c02eeef3df8',
    '38f5d18bd8522c244bdd70cb4a68e0e718865155811c043f052fb9f1c51de662',
  };

  @override
  void initState() {
    super.initState();
    ReownAppKitModalNetworks.addNetworks('eip155', [customNetwork]);
    ReownAppKitModalNetworks.removeNetworks('eip155', [
      '10',
      '100',
      '137',
      '324',
      '1101',
      '5000',
      '8217',
      '42161',
      '42220',
      '43114',
      '59144',
      '7777777',
      '1313161554'
    ]);
    initializeAppKitModal();
  }

  void initializeAppKitModal() async {
    _appKitModal = ReownAppKitModal(
      context: context,
      projectId:
          '40e5897bd6b0d9d2b27b717ec50906c3', // Replace with your actual project ID
      metadata: const PairingMetadata(
        name: 'Crypto Flutter',
        description: 'A Crypto Flutter Example App',
        url: 'https://www.reown.com/',
        icons: ['https://reown.com/reown-logo.png'],
        redirect: Redirect(
          native: 'cryptoflutter://',
          universal: 'https://reown.com',
          linkMode: true,
        ),
      ),
      featuredWalletIds: featuredWalletIds,
    );

    try {
      if (_appKitModal != null) {
        await _appKitModal!.init();
        debugPrint('appKitModal initialized successfully.');

        // Check if session is available
        if (_appKitModal!.session != null) {
          debugPrint(
              'Current wallet address: ${_appKitModal!.session!.address}');
          updateWalletAddress();
        } else {
          debugPrint('Session is null after initialization.');
        }
      } else {
        debugPrint('appKitModal is null, skipping initialization.');
      }
    } catch (e) {
      debugPrint('Error during appKitModal initialization: $e');
    }

    _appKitModal?.addListener(() {
      updateWalletAddress();
    });

    setState(() {});
  }

  void updateWalletAddress() {
    setState(() {
      if (_appKitModal?.session != null) {
        walletAddress = _appKitModal!.session!.address ?? 'No Address';
        _balance = _appKitModal!.balanceNotifier.value.isEmpty
            ? '0'
            : _appKitModal!.balanceNotifier.value; // Use the balance
      } else {
        walletAddress = 'No Address';
        _balance = '0';
      }
      debugPrint('Wallet address updated: $walletAddress');
      debugPrint('Balance updated: $_balance');
    });
  }

  void openWalletApp() {
    if (_appKitModal != null && _appKitModal!.isConnected) {
      try {
        // Launch the connected wallet using the launchConnectedWallet method
        _appKitModal!.launchConnectedWallet();
        debugPrint('Launching connected wallet...');
      } catch (e) {
        debugPrint('Error launching connected wallet: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to launch wallet: $e')),
        );
      }
    } else {
      debugPrint('No wallet connected or session is invalid.');
    }
  }

  Future<void> testTransaction(String receiver, String amount) async {
    if (receiver.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid receiver address!')),
      );
      return; // Exit the function if the address is invalid
    }
    _appKitModal!.launchConnectedWallet();
    debugPrint(
        'Debug Transaction: Testing transaction with receiver: $receiver and amount: $amount');

    // Convert amount to Ether
    double amountInEther = double.parse(amount);
    debugPrint('Debug Transaction: Amount in Ether: $amountInEther');

    // Convert Ether amount to Wei
    BigInt amountInWei = BigInt.from((amountInEther * pow(10, 18)).toInt());
    EtherAmount txValue =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, amountInWei);
    debugPrint('Debug Transaction: Amount in Wei: $amountInWei');

    BigInt balanceInWeiValue;

    try {
      // Get sender address and current balance
      final senderAddress = _appKitModal!.session!.address!;
      debugPrint('Debug Transaction: Sender Address: $senderAddress');

      final currentBalance = _appKitModal!.balanceNotifier.value;
      debugPrint('Debug Transaction: Current Balance: $currentBalance');

      // Check if balance is empty
      if (currentBalance.isEmpty) {
        throw Exception('Unable to fetch wallet balance.');
      }

      // Convert current balance to Ether and then to Wei
      double balanceInEther = double.parse(currentBalance.split(' ')[0]);
      balanceInWeiValue = BigInt.from((balanceInEther * pow(10, 18)).toInt());
      debugPrint('Debug Transaction: Balance in Ether: $balanceInEther');
    } catch (e) {
      debugPrint('Debug Transaction: Error parsing wallet balance: $e');
      throw Exception('Error parsing wallet balance: $e');
    }

    // Create EtherAmount for current balance in Wei
    final balanceInWei =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, balanceInWeiValue);
    debugPrint('Debug Transaction: Balance in Wei: $balanceInWei');

    // Calculate total cost including transaction fee
    final gasPrice = BigInt.from(1000000000); // 1 Gwei
    final gasLimit = BigInt.from(200000); // Standard gas limit for ETH transfer
    final totalCost =
        txValue.getInWei + (gasPrice * gasLimit); // Include gas fees
    debugPrint(
        'Debug Transaction: Total Cost (including gas fees): $totalCost');

    // Check if the balance is sufficient for the transaction
    if (balanceInWei.getInWei < totalCost) {
      throw Exception(
          'Insufficient funds for transaction! Balance: ${balanceInWei.getInWei}, Total Cost: $totalCost');
    }

    // Define the contract and its ABI
    final tetherContract = DeployedContract(
      ContractAbi.fromJson(
        jsonEncode([
          {
            "constant": false,
            "inputs": [
              {"internalType": "address", "name": "_to", "type": "address"},
              {"internalType": "uint256", "name": "_value", "type": "uint256"}
            ],
            "name": "transfer",
            "outputs": [],
            "payable": false,
            "stateMutability": "nonpayable",
            "type": "function"
          }
        ]),
        'ETH',
      ),
      EthereumAddress.fromHex(receiver),
    );

    // Send the transaction
    try {
      final result = await _appKitModal!.requestWriteContract(
        topic: _appKitModal!.session!.topic,
        chainId: _appKitModal!.selectedChain!.chainId,
        deployedContract: tetherContract,
        functionName: 'transfer',
        transaction: Transaction(
          from: EthereumAddress.fromHex(_appKitModal!.session!.address!),
          to: EthereumAddress.fromHex(receiver),
          value: txValue,
          maxGas: gasLimit.toInt(),
        ),
        parameters: [
          EthereumAddress.fromHex(receiver),
          amountInWei, // Amount in Wei
        ],
      );
      debugPrint('Debug Transaction: Transaction request result: $result');
      // _appKitModal!.launchConnectedWallet();
      // Handle result
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction failed.')),
        );
      }
    } catch (e) {
      // Enhanced error handling
      debugPrint('Debug Transaction: Transaction error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction error: $e')),
      );
    }
  }

  // Widget for displaying a loading indicator
  Widget loadingIndicator() {
    return isLoading
        ? const CircularProgressIndicator()
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AppKitModal instance: $_appKitModal');
    final TextEditingController addressController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Flutter App'),
      ),
      body: Center(
        child: SingleChildScrollView(
          // Allow scrolling if content overflows
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Button to select a network
              if (_appKitModal != null)
                AppKitModalNetworkSelectButton(appKit: _appKitModal!),

              const SizedBox(height: 20),

              // Button to connect the wallet
              if (_appKitModal != null)
                Visibility(
                  visible: _appKitModal?.isConnected ?? false,
                  child: AppKitModalConnectButton(appKit: _appKitModal!),
                ),

              const SizedBox(height: 20),

              // Display the connected wallet address
              Text('Connected Wallet: $walletAddress'),
              const SizedBox(height: 10),

              // Display the wallet balance
              Text('Balance: $_balance'),
              const SizedBox(height: 20),

              // Button to launch the wallet app
              ElevatedButton(
                onPressed: openWalletApp,
                child: const Text('Open Wallet App'),
              ),

              const SizedBox(height: 20),

              // Grouped TextFields and Sign Message Button
              if (_appKitModal != null)
                Visibility(
                  visible: _appKitModal?.isConnected ?? false,
                  child: Column(
                    children: [
                      // Receiver Address TextField
                      Container(
                        width: 250, // Set the width to make it smaller
                        child: TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: 'Receiver Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 20.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Amount TextField
                      Container(
                        width: 250, // Set the width to make it smaller
                        child: TextField(
                          controller: amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 20.0),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      ElevatedButton(
                        onPressed: () {
                          String recipient = addressController.text;
                          String amount = amountController.text;
                          testTransaction(recipient, amount);
                        },
                        child: const Text('Test Transaction'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              loadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// final tetherContract = DeployedContract(
//       ContractAbi.fromJson(
//         jsonEncode([
//           {
//             "constant": false,
//             "inputs": [
//               {"internalType": "address", "name": "_to", "type": "address"},
//               {"internalType": "uint256", "name": "_value", "type": "uint256"}
//             ],
//             "name": "transfer",
//             "outputs": [],
//             "payable": false,
//             "stateMutability": "nonpayable",
//             "type": "function"
//           }
//         ]), // ABI object
//         'ETH', // Name of the contract for clarity
//       ),
//       EthereumAddress.fromHex(
//           receiver), // Tether contract address
//     );
