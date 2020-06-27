require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjectsService

  def feed(date)
    get_url('/neo/rest/v1/feed', date)
  end

  def get_url(url, date)
    conn = Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
      asteroids_list_data = conn.get(url)
      JSON.parse(asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end
end

class NearEarthObjectsSearch

  def near_earth_objects(date)

   service.feed(date).map do |data|
     Astroid.new(data)
   end


  end

  def service
    NearEarthObjectsService.new
  end

end

class Astroid
  attr_reader :name, :diameter, :miss_distance
  def initialize(data)
    @name = data[:name]
    @diameter = data[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    @miss_distance = data[:close_approach_data][0][:miss_distance][:miles].to_i
  end
end

class NearEarthObjects


  def self.find_neos_by_date(date)
    search =   NearEarthObjectsSearch.new

    {
     astroid_list: self.formatted_astroid_data(search, date),
     biggest_astroid: largest_astroid_diameter(search, date),
     total_number_of_astroids: total_number_of_astroids(search, date)
   }

  end

  def self.formatted_astroid_data(search, date)

    search.near_earth_objects(date).map do |astroid|
      {
        name: astroid.name,
        diameter: "#{astroid.diameter} ft",
        miss_distance: "#{astroid.miss_distance} miles"
      }
    end
  end

  def self.largest_astroid_diameter(search, date)
    search.near_earth_objects(date).max do |astroid|
      astroid.diameter
    end
  end

  def self.total_number_of_astroids(search, date)
    search.near_earth_objects(date).count
  end


end
