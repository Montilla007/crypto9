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


  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    // Print the appKit instance for debugging
    debugPrint('AppKitModal instance: $_appKitModal');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crypto Flutter App'),
      ),
      body: Center(
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

            // Only show the account button if the user is connected
            Visibility(
              visible: _appKitModal?.isConnected ?? false,
              child: AppKitModalAccountButton(appKit: _appKitModal!),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: MyHomePage(),
  ));
}
