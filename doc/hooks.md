# Sistema de Hooks do FeaturePack

## Hook after_initialize

O FeaturePack agora suporta hooks `after_initialize` que permitem executar código customizado após o carregamento de grupos e features.

### Como funciona

Durante o processo de setup do FeaturePack, após todos os grupos e features serem descobertos e configurados, o sistema procura e executa arquivos `after_initialize.rb` específicos.

### Localização dos arquivos

- **Para grupos**: `app/feature_packs/[nome_do_grupo]/_group_space/after_initialize.rb`
- **Para features**: `app/feature_packs/[nome_do_grupo]/[nome_da_feature]/after_initialize.rb`

### Contexto de execução

Os arquivos `after_initialize.rb` são executados no contexto do objeto group ou feature, permitindo acesso direto a todas as suas propriedades através de `self`.

### Exemplos de uso

#### Hook para grupo

```ruby
# app/feature_packs/group_admin/_group_space/after_initialize.rb

# Registrar o grupo em um sistema de auditoria
Rails.logger.info "Grupo #{name} carregado com #{features.size} features"

# Configurar permissões globais do grupo
features.each do |feature|
  Rails.logger.info "  - Feature #{feature.name} disponível em #{feature.manifest[:url]}"
end

# Carregar configurações específicas do grupo
config_file = File.join(absolute_path, GROUP_SPACE_DIRECTORY, 'config.yml')
if File.exist?(config_file)
  @config = YAML.load_file(config_file)
end
```

#### Hook para feature

```ruby
# app/feature_packs/group_admin/feature_users/after_initialize.rb

# Registrar rotas dinâmicas
Rails.logger.info "Feature #{name} inicializada no grupo #{group.name}"

# Verificar dependências
required_gems = %w[devise cancancan]
required_gems.each do |gem_name|
  unless Gem.loaded_specs.key?(gem_name)
    Rails.logger.warn "Feature #{name} requer a gem #{gem_name}"
  end
end

# Registrar a feature em um sistema de métricas
StatsD.increment("features.#{group.name}.#{name}.loaded")

# Configurar cache específico da feature
Rails.cache.write("feature:#{group.name}:#{name}:loaded_at", Time.current)
```

### Propriedades disponíveis

#### No contexto de grupo

- `name` - Nome do grupo (symbol)
- `absolute_path` - Caminho absoluto do grupo
- `relative_path` - Caminho relativo do grupo
- `features` - Array com todas as features do grupo
- `manifest` - Hash com dados do manifest.yaml
- `routes_file` - Caminho do arquivo de rotas

#### No contexto de feature

- `name` - Nome da feature (symbol)
- `group` - Referência ao grupo pai
- `absolute_path` - Caminho absoluto da feature
- `relative_path` - Caminho relativo da feature
- `namespace` - Módulo Ruby da feature
- `manifest` - Hash com dados do manifest.yaml
- `routes_file` - Caminho do arquivo de rotas

### Casos de uso comuns

1. **Logging e auditoria** - Registrar quando grupos/features são carregados
2. **Validação de dependências** - Verificar se gems ou recursos necessários estão disponíveis
3. **Configuração dinâmica** - Carregar configurações específicas
4. **Registro em sistemas externos** - Integrar com sistemas de métricas ou monitoramento
5. **Inicialização de recursos** - Preparar caches, conexões ou outros recursos
6. **Verificação de segurança** - Validar permissões ou políticas de acesso

### Boas práticas

1. Mantenha os hooks leves e rápidos - eles são executados durante o boot da aplicação
2. Use logging apropriado para facilitar debug
3. Trate exceções adequadamente para não quebrar o processo de inicialização
4. Evite operações síncronas pesadas (I/O, rede, etc)
5. Use o hook apenas para configurações que realmente precisam acontecer após a carga completa

### Ordem de execução

1. Todos os grupos são descobertos e configurados
2. Todas as features são descobertas e configuradas
3. Hooks `after_initialize` dos grupos são executados
4. Hooks `after_initialize` das features são executados (na ordem de descoberta)