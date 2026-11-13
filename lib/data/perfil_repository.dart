import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/perfil.dart';

class PerfilRepositoryException implements Exception {
  const PerfilRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PerfilRepository {
  // Mantém uma única abertura do banco enquanto este repositório estiver ativo.
  Future<Database>? _databaseFuture;

  Future<Database> get _database {
    return _databaseFuture ??= _abrirBanco();
  }

  Future<Database> _abrirBanco() async {
    try {
      final caminho = p.join(await getDatabasesPath(), 'equilibra.db');

      return await openDatabase(
        caminho,
        version: 2,
        onCreate: (banco, versao) async {
          await banco.execute('''
            CREATE TABLE perfil (
              id INTEGER PRIMARY KEY,
              nome TEXT NOT NULL,
              idade INTEGER NOT NULL,
              peso REAL NOT NULL,
              meta TEXT NOT NULL,
              sexo TEXT,
              altura INTEGER,
              pratica_atividade INTEGER NOT NULL DEFAULT 0,
              dias_atividade INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
        // v1 -> v2: acrescenta colunas sem apagar o perfil já salvo.
        onUpgrade: (banco, versaoAntiga, versaoNova) async {
          if (versaoAntiga < 2) {
            await banco.execute('ALTER TABLE perfil ADD COLUMN sexo TEXT');
            await banco.execute('ALTER TABLE perfil ADD COLUMN altura INTEGER');
            await banco.execute(
              'ALTER TABLE perfil ADD COLUMN pratica_atividade '
              'INTEGER NOT NULL DEFAULT 0',
            );
            await banco.execute(
              'ALTER TABLE perfil ADD COLUMN dias_atividade '
              'INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );
    } on DatabaseException {
      throw const PerfilRepositoryException(
        'Não foi possível abrir o banco de dados.',
      );
    }
  }

  Future<Perfil?> buscarPerfil() async {
    try {
      final banco = await _database;
      final registros = await banco.query(
        'perfil',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (registros.isEmpty) return null;
      return Perfil.fromMap(registros.first);
    } on PerfilRepositoryException {
      rethrow;
    } on DatabaseException {
      throw const PerfilRepositoryException(
        'Não foi possível carregar os dados do perfil.',
      );
    }
  }

  Future<void> salvarPerfil(Perfil perfil) async {
    try {
      final banco = await _database;
      await banco.insert(
        'perfil',
        {
          'id': 1,
          ...perfil.toMap(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on PerfilRepositoryException {
      rethrow;
    } on DatabaseException {
      throw const PerfilRepositoryException(
        'Não foi possível salvar os dados do perfil.',
      );
    }
  }
}