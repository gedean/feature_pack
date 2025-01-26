rm *.gem
gem build feature_pack.gemspec
# Lista todos os arquivos .gem, ordena alfabeticamente e pega o último
latest_gem=$(ls -1 *.gem | sort | tail -n 1)
# Instala o arquivo .gem mais recente
gem install "$latest_gem"