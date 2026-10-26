import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

/// Keadaan sebuah transaksi di blockchain.
enum TxState { pending, confirmed, failed }

/// Pintu ke blockchain. Dibuat sebagai antarmuka supaya bisa diganti versi palsu saat tes.
abstract class BlockchainService {
  /// False kalau alamat node atau kunci dompet belum diisi di lib/config/secrets.dart.
  bool get isConfigured;

  /// Alamat halaman bukti transaksi di Etherscan.
  String explorerUrl(String txHash);

  /// Menulis [payload] ke blockchain lewat satu transaksi, mengembalikan nomor transaksinya.
  Future<String> sendPayload(String payload);

  Future<TxState> stateOf(String txHash);

  /// Isi transaksi yang tercatat di blockchain, atau null kalau transaksinya tidak ditemukan.
  Future<String?> payloadOf(String txHash);
}

/// Menulis dan membaca transaksi di Ethereum Sepolia (jaringan uji publik, ETH-nya tidak bernilai).
/// Transaksi dikirim ke alamat dompet sendiri dengan nilai nol, hanya membawa isi teks.
/// Kunci pribadi ada di dalam aplikasi, jadi hanya aman dipakai untuk dompet uji.
class SepoliaBlockchainService implements BlockchainService {
  SepoliaBlockchainService(
    http.Client httpClient, {
    required String rpcUrl,
    required String privateKeyHex,
  })  : _privateKeyHex = privateKeyHex,
        _isConfigured = rpcUrl.isNotEmpty && privateKeyHex.isNotEmpty,
        _client = Web3Client(rpcUrl.isEmpty ? 'http://localhost' : rpcUrl, httpClient);

  /// Nomor jaringan Sepolia, ikut ditandatangani supaya transaksi tidak bisa dipakai di jaringan lain.
  static const int _chainId = 11155111;

  final Web3Client _client;
  final String _privateKeyHex;
  final bool _isConfigured;

  @override
  bool get isConfigured => _isConfigured;

  @override
  String explorerUrl(String txHash) => 'https://sepolia.etherscan.io/tx/$txHash';

  @override
  Future<String> sendPayload(String payload) async {
    // Kunci dibaca di sini, bukan di constructor, supaya kunci yang salah ketik tidak membuat aplikasi gagal start.
    final credentials = EthPrivateKey.fromHex(_privateKeyHex);
    final transaction = Transaction(
      to: credentials.address,
      data: Uint8List.fromList(utf8.encode(payload)),
    );
    return _client.sendTransaction(credentials, transaction, chainId: _chainId);
  }

  @override
  Future<TxState> stateOf(String txHash) async {
    final receipt = await _client.getTransactionReceipt(txHash);
    if (receipt == null) return TxState.pending;
    return receipt.status == false ? TxState.failed : TxState.confirmed;
  }

  @override
  Future<String?> payloadOf(String txHash) async {
    final info = await _client.getTransactionByHash(txHash);
    if (info == null) return null;
    return utf8.decode(info.input, allowMalformed: true);
  }
}
