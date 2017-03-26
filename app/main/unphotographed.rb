class Unphotographed
  LABS_API = 'http://tools.wmflabs.org/articles-by-lat-lon-without-images/index.php'
  # http://tools.wmflabs.org/articles-by-lat-lon-without-images/index.php?wiki=en&lat=59.06708056&lon=16.36239722&radius=10000&reencode=true

  def self.near(coordinates)
    nearby = new(coordinates)
    nearby.wikipedia || nearby.wikidata
  end

  def initialize(coordinates)
    @lat = coordinates[0]
    @lon = coordinates[1]
  end

  def wikipedia
    @project = 'wikipedia'
    nearest(fetch_nearby)
  end

  def wikidata
    @project = 'wikidata'
    nearest(fetch_nearby)
  end

  def fetch_nearby
    response = Net::HTTP.get(URI.parse(query_url))
    pp query_url
    pp response
    JSON.parse(response)
  end

  def query_url
    "#{LABS_API}?wiki=#{@project}&lat=#{@lat}&lon=#{@lon}&radius=10000&reencode=true"
  end

  def nearest(results)
    sorted = results.sort_by do |result|
      result_lat = result['lat']
      result_lon = result['lon']
      Haversine.distance(result_lat, result_lon, @lat, @lon)
    end
    sorted.first
  end
end
