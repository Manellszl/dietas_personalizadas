import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'calorias_repository.dart';

class RefeicaoSalva {
  const RefeicaoSalva({
    this.id,
    required this.nome,
    required this.data,
    this.concluida = false,
    this.alimentos = const [],
  });

  final int? id;
  final String nome;
  final DateTime data;
  final bool concluida;
  final List<AlimentoSalvo> alimentos;

  double get calorias {
    return alimentos.fold(0, (total, alimento) => total + alimento.calorias);
  }

  RefeicaoSalva copiarCom({
    int? id,
    String? nome,
    DateTime? data,
    bool? concluida,
    List<AlimentoSalvo>? alimentos,
  }) {
    return RefeicaoSalva(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      data: data ?? this.data,
      concluida: concluida ?? this.concluida,
      alimentos: alimentos ?? this.alimentos,
    );
  }
}

class AlimentoSalvo {
  const AlimentoSalvo({
    this.id,
    required this.refeicaoId,
    required this.nome,
    required this.gramas,
    required this.caloriasPor100g,
  });

  final int? id;
  final int refeicaoId;
  final String nome;
  final double gramas;
  final double caloriasPor100g;

  double get calorias => gramas * caloriasPor100g / 100;

  factory AlimentoSalvo.fromMap(Map<String, Object?> map) {
    return AlimentoSalvo(
      id: map['id'] as int,
      refeicaoId: map['refeicao_id'] as int,
      nome: map['nome'] as String,
      gramas: (map['gramas'] as num).toDouble(),
      caloriasPor100g: (map['calorias_por_100g'] as num).toDouble(),
    );
  }
}

class ResumoDia {
  const ResumoDia({
    required this.data,
    required this.meta,
    required this.consumidas,
    required this.atingiuMeta,
  });

  final DateTime data;
  final int meta;
  final int consumidas;
  final bool atingiuMeta;

  factory ResumoDia.fromMap(Map<String, Object?> map) {
    return ResumoDia(
      data: DateTime.parse(map['data'] as String),
      meta: map['meta'] as int,
      consumidas: map['consumidas'] as int,
      atingiuMeta: (map['atingiu_meta'] as int) == 1,
    );
  }
}

class RefeicoesRepository {
  Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _abrirBanco();

  Future<Database> _abrirBanco() async {
    final caminho = p.join(await getDatabasesPath(), 'equilibra_refeicoes.db');

    return openDatabase(
      caminho,
      version: 4,
      onConfigure: (banco) async {
        await banco.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (banco, versao) async {
        await _criarTabelas(banco);
      },
      onUpgrade: (banco, antiga, nova) async {
        if (antiga < 2) {
          await _criarTabelaResumo(banco);
        }
        if (antiga < 4) { await _criarFavoritos(banco); }
        if (antiga < 3) {
          await _criarCatalogos(banco);
          await banco.execute("INSERT OR IGNORE INTO rotina_refeicoes (nome, desde) SELECT nome, MIN(data) FROM refeicoes GROUP BY nome");
        }
      },
    );
  }

  Future<void> _criarTabelas(DatabaseExecutor banco) async {
    await banco.execute('''
      CREATE TABLE refeicoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        data TEXT NOT NULL,
        concluida INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await banco.execute('''
      CREATE TABLE alimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refeicao_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        gramas REAL NOT NULL,
        calorias_por_100g REAL NOT NULL,
        FOREIGN KEY (refeicao_id)
          REFERENCES refeicoes(id)
          ON DELETE CASCADE
      )
    ''');

    await _criarTabelaResumo(banco);
    await _criarCatalogos(banco);
    await _criarFavoritos(banco);
  }

  Future<void> _criarTabelaResumo(DatabaseExecutor banco) async {
    await banco.execute('''
      CREATE TABLE IF NOT EXISTS resumo_diario (
        data TEXT PRIMARY KEY,
        meta INTEGER NOT NULL,
        consumidas INTEGER NOT NULL,
        atingiu_meta INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _criarCatalogos(DatabaseExecutor banco) async {
    await banco.execute('''
      CREATE TABLE IF NOT EXISTS catalogo_alimentos (
        chave TEXT PRIMARY KEY, nome TEXT NOT NULL,
        calorias_por_100g REAL NOT NULL
      )
    ''');
    await banco.execute('''
      CREATE TABLE IF NOT EXISTS rotina_refeicoes (
        nome TEXT PRIMARY KEY COLLATE NOCASE, desde TEXT NOT NULL
      )
    ''');
    await banco.execute('CREATE TABLE IF NOT EXISTS refeicoes_excluidas (nome TEXT COLLATE NOCASE, data TEXT, PRIMARY KEY(nome, data))');
    for (final nome in ['Café da manhã', 'Almoço', 'Jantar']) {
      await banco.insert('rotina_refeicoes', {'nome': nome, 'desde': '0001-01-01'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _criarFavoritos(DatabaseExecutor banco) async {
    await banco.execute('CREATE TABLE IF NOT EXISTS favoritos (chave TEXT PRIMARY KEY, nome TEXT NOT NULL, calorias_por_100g REAL NOT NULL)');
  }

  Future<List<AlimentoInfo>> buscarFavoritos() async {
    final banco = await _database;
    return (await banco.query('favoritos', orderBy: 'nome')).map(_info).toList();
  }

  AlimentoInfo _info(Map<String, Object?> r) => AlimentoInfo(
    nome: r['nome'] as String,
    caloriasPor100g: (r['calorias_por_100g'] as num).toDouble(),
  );

  Future<void> definirFavorito(AlimentoInfo alimento, bool favorito) async {
    final banco = await _database;
    final chave = CaloriasRepository.normalizar(alimento.nome);
    if (favorito) {
      await banco.insert('favoritos', {'chave': chave, 'nome': alimento.nome,
        'calorias_por_100g': alimento.caloriasPor100g}, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await banco.delete('favoritos', where: 'chave = ?', whereArgs: [chave]);
    }
  }

  Future<List<AlimentoInfo>> buscarRecentes() async {
    final banco = await _database;
    final rows = await banco.query('alimentos', orderBy: 'id DESC');
    final vistos = <String>{};
    return rows.map(_info).where((a) => vistos.add(CaloriasRepository.normalizar(a.nome))).take(20).toList();
  }

  Future<void> editarQuantidade(int id, double gramas) async {
    if (!gramas.isFinite || gramas <= 0 || gramas > 5000) throw ArgumentError('Quantidade inválida');
    final banco = await _database;
    await banco.update('alimentos', {'gramas': gramas}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, ResumoDia>> buscarResumosPeriodo(DateTime inicio, DateTime fim) async {
    final banco = await _database;
    final rows = await banco.query('resumo_diario', where: 'data BETWEEN ? AND ?', whereArgs: [dataComoTexto(inicio), dataComoTexto(fim)]);
    return {for (final row in rows) row['data'] as String: ResumoDia.fromMap(row)};
  }

  // Copia somente alimentos; preserva registros existentes e não duplica por engano.
  Future<int> copiarAlimentos(DateTime origem, DateTime destino, {String? nome}) async {
    if (dataComoTexto(origem) == dataComoTexto(destino)) throw ArgumentError('Escolha outro dia');
    final banco = await _database;
    return banco.transaction((tx) async {
      final fontes = await tx.query('refeicoes', where: 'data = ?${nome == null ? "" : " AND nome = ? COLLATE NOCASE"}', whereArgs: [dataComoTexto(origem), ?nome]);
      var copiados = 0;
      for (final fonte in fontes) {
        final itens = await tx.query('alimentos', where: 'refeicao_id = ?', whereArgs: [fonte['id']]);
        if (itens.isEmpty) continue;
        final n = fonte['nome'] as String;
        final dia = dataComoTexto(destino);
        final alvos = await tx.query('refeicoes', where: 'data = ? AND nome = ? COLLATE NOCASE', whereArgs: [dia, n]);
        final int id;
        if (alvos.isEmpty) {
          await tx.delete('refeicoes_excluidas', where: 'nome = ? COLLATE NOCASE AND data = ?', whereArgs: [n, dia]);
          id = await tx.insert('refeicoes', {'nome': n, 'data': dia, 'concluida': 0});
        } else {
          id = alvos.first['id'] as int;
          if ((await tx.query('alimentos', where: 'refeicao_id = ?', whereArgs: [id], limit: 1)).isNotEmpty) continue;
        }
        for (final item in itens) {
          await tx.insert('alimentos', {'refeicao_id': id, 'nome': item['nome'], 'gramas': item['gramas'], 'calorias_por_100g': item['calorias_por_100g']});
          copiados++;
        }
      }
      return copiados;
    });
  }

  Future<List<AlimentoInfo>> buscarAlimentosPersonalizados() async {
    final banco = await _database;
    final rows = await banco.query('catalogo_alimentos', orderBy: 'nome');
    return rows.map((r) => AlimentoInfo(
      nome: r['nome'] as String,
      caloriasPor100g: (r['calorias_por_100g'] as num).toDouble(),
    )).toList();
  }

  Future<void> adicionarRefeicaoRotina(String nome, DateTime data) async {
    final banco = await _database;
    await banco.transaction((tx) async {
      final chave = dataComoTexto(data);
      await tx.insert('rotina_refeicoes', {'nome': nome, 'desde': chave},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await tx.delete('refeicoes_excluidas', where: 'nome = ? COLLATE NOCASE AND data = ?', whereArgs: [nome, chave]);
      final existentes = await tx.query('refeicoes',
          where: 'data = ? AND nome = ? COLLATE NOCASE', whereArgs: [chave, nome]);
      if (existentes.isEmpty) {
        await tx.insert('refeicoes', {'nome': nome, 'data': chave, 'concluida': 0});
      }
    });
  }

  String dataComoTexto(DateTime data) {
    final ano = data.year.toString().padLeft(4, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');

    return '$ano-$mes-$dia';
  }

  Future<RefeicaoSalva> salvarRefeicao(RefeicaoSalva refeicao) async {
    final banco = await _database;

    final valores = {
      'nome': refeicao.nome,
      'data': dataComoTexto(refeicao.data),
      'concluida': refeicao.concluida ? 1 : 0,
    };

    if (refeicao.id == null) {
      final id = await banco.insert('refeicoes', valores);
      return refeicao.copiarCom(id: id);
    }

    await banco.update(
      'refeicoes',
      valores,
      where: 'id = ?',
      whereArgs: [refeicao.id],
    );

    return refeicao;
  }

  Future<void> removerResumoDia(DateTime data) async {
    final banco = await _database;

    await banco.delete(
      'resumo_diario',
      where: 'data = ?',
      whereArgs: [dataComoTexto(data)],
    );
  }

  Future<List<RefeicaoSalva>> buscarRefeicoesDoDia(DateTime data) async {
    final banco = await _database;

    final registros = await banco.query(
      'refeicoes',
      where: 'data = ?',
      whereArgs: [dataComoTexto(data)],
      orderBy: 'id ASC',
    );

    final resultado = <RefeicaoSalva>[];

    for (final registro in registros) {
      final id = registro['id'] as int;

      final alimentos = await banco.query(
        'alimentos',
        where: 'refeicao_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );

      resultado.add(
        RefeicaoSalva(
          id: id,
          nome: registro['nome'] as String,
          data: DateTime.parse(registro['data'] as String),
          concluida: (registro['concluida'] as int) == 1,
          alimentos: alimentos.map(AlimentoSalvo.fromMap).toList(),
        ),
      );
    }

    return resultado;
  }

  Future<void> criarRefeicoesIniciaisSeVazio(DateTime data) async {
    final banco = await _database;
    final chave = dataComoTexto(data);
    await banco.transaction((tx) async {
      final rotina = await tx.query('rotina_refeicoes', where: 'desde <= ?',
          whereArgs: [chave], orderBy: 'rowid');
      for (final item in rotina) {
        final nome = item['nome'] as String;
        final excluidas = await tx.query('refeicoes_excluidas', where: 'nome = ? COLLATE NOCASE AND data = ?', whereArgs: [nome, chave]);
        if (excluidas.isNotEmpty) continue;
        final existentes = await tx.query('refeicoes',
            where: 'data = ? AND nome = ? COLLATE NOCASE', whereArgs: [chave, nome]);
        if (existentes.isEmpty) {
          await tx.insert('refeicoes', {'nome': nome, 'data': chave, 'concluida': 0});
        }
      }
    });
  }

  Future<AlimentoSalvo> adicionarAlimento(AlimentoSalvo alimento, {bool personalizado = false}) async {
    final banco = await _database;

    final id = await banco.transaction((tx) async {
      if (personalizado) {
        await tx.insert('catalogo_alimentos', {
          'chave': CaloriasRepository.normalizar(alimento.nome),
          'nome': alimento.nome,
          'calorias_por_100g': alimento.caloriasPor100g,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return tx.insert('alimentos', {
      'refeicao_id': alimento.refeicaoId,
      'nome': alimento.nome,
      'gramas': alimento.gramas,
      'calorias_por_100g': alimento.caloriasPor100g,
      });
    });

    return AlimentoSalvo(
      id: id,
      refeicaoId: alimento.refeicaoId,
      nome: alimento.nome,
      gramas: alimento.gramas,
      caloriasPor100g: alimento.caloriasPor100g,
    );
  }

  Future<void> removerAlimento(int id) async {
    final banco = await _database;

    await banco.delete('alimentos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removerRefeicao(int id) async {
    final banco = await _database;

    await banco.transaction((tx) async {
      final rows = await tx.query('refeicoes', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return;
      final nome = rows.first['nome'] as String;
      final data = rows.first['data'] as String;
      await tx.insert('refeicoes_excluidas', {'nome': nome, 'data': data},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await tx.delete('refeicoes', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> salvarResumoDia({
    required DateTime data,
    required int meta,
    required int consumidas,
    required bool atingiuMeta,
  }) async {
    final banco = await _database;

    await banco.insert('resumo_diario', {
      'data': dataComoTexto(data),
      'meta': meta,
      'consumidas': consumidas,
      'atingiu_meta': atingiuMeta ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, ResumoDia>> buscarResumosDoMes(DateTime mes) async {
    final banco = await _database;

    final primeiroDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);

    final registros = await banco.query(
      'resumo_diario',
      where: 'data >= ? AND data <= ?',
      whereArgs: [dataComoTexto(primeiroDia), dataComoTexto(ultimoDia)],
    );

    final resultado = <String, ResumoDia>{};

    for (final registro in registros) {
      final resumo = ResumoDia.fromMap(registro);
      resultado[dataComoTexto(resumo.data)] = resumo;
    }

    return resultado;
  }
}
