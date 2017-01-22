require 'oauth'
require 'json'

$consumer = OAuth::Consumer.new(
  "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd",
  "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151")

def get_doc(url, id)
  response = $consumer.request(:get, "#{url}#{id}")
  return JSON.parse(response.body)['data']
end

def get_documents()
  url = 'https://kitsu.io/api/edge/anime/'
  attr_set = ['slug', 'synopsis', 'ratingFrequencies', 'averageRating',
              'startDate', 'endDate', 'popularityRank', 'ratingRank', 'ageRating',
              'ageRatingGuide', 'episodeCount']

  docs = Array.new
  for id in 1..5
    if id > 2 then
      break
    end
    doc = get_doc(url, id)
    docs << doc
    puts "#{id}: #{doc['attributes']['slug']}"
  end

  return docs
end

docs = get_documents()
print docs
