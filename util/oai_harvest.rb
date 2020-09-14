require 'oai'
#url = "https://opus4.kobv.de/opus4-udk/oai?verb=GetRecord&metadataPrefix=oai_dc&identifier=oai:kobv.de-opus4-udk:78"
#url = "https://opus4.kobv.de/opus4-udk/oai"
url = "https://eu02.alma.exlibrisgroup.com/view/oai/43ACC_ONB/request?verb=ListRecords&metadataPrefix=marc21&set=MUSHANMARC"
#url = "https://eu02.alma.exlibrisgroup.com/view/oai/43ACC_ONB/request?"
client = OAI::Client.new url# :headers => { "identifier" => "oai:alma.ACCONB:9958492376403338", "set" => "MUSHANMARC", "metadataPrefix" => "marc21" }
#client = OAI::Client.new url, :headers => { "identifier" => "oai:kobv.de-opus4-udk:78" }
  response = client.list_records
  # Get the first page of records
  response.each do |record| 
         puts record.metadata
  end
  #et the second page of records
# response = client.list_records(:resumption_token => response.resumption_token)
# response.each do |record|
#   puts record.metadata
# end
  # Get all pages together (may take a *very* long time to complete)
# client.list_records.full.each do |record|
#   puts record.metadata
# end
