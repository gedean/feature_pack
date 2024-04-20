# Params

`SAMPLE` 
```ruby
cp_params = CrescimentoPopulacional::Params.new entity_id: 150570, start_year: 2018, end_year: 2022

calc = CrescimentoPopulacional::Calculator.new(params: cp_params)
```