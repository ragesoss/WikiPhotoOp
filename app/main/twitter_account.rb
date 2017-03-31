require 'twitter'

class TwitterAccount
  attr_reader :client
  ###############
  # Twitter API #
  ###############
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['twitter_consumer_key']
      config.consumer_secret = ENV['twitter_consumer_secret']
      config.access_token = ENV['twitter_access_token']
      config.access_token_secret = ENV['twitter_access_token_secret']
    end
  end

  def recent_mentions
    client.mentions_timeline
  end

  def reply_to_recent_mentions
    reply_to(recent_mentions)
  end

  def reply_to(tweets)
    Rails.logger.info 'Processing tweets'
    tweets.each do |tweet|
      next if Mention.exists?(status_id: tweet.id)
      coordinates = tweet&.geo&.coordinates
      coordinates ||= place_coordinates(tweet)
      next unless coordinates
      nearest = Unphotographed.near(coordinates)
      opts = reply_tweet_options(tweet, nearest)
      text = reply_tweet_text(tweet, nearest)
      update(text, opts)
      Rails.logger.info "Tweeted reply to #{tweet.id}!"
      Mention.create(status_id: tweet.id)
    end
  end

  def place_coordinates(tweet)
    coordinates_set = tweet&.place&.bounding_box&.coordinates
    return unless coordinates_set
    latitudes = []
    longitudes = []
    coordinates_set[0].each do |coordinates|
      latitudes << coordinates[0]
      longitudes << coordinates[1]
    end
    average_lat = latitudes.sum / latitudes.size
    average_long = longitudes.sum / longitudes.size
    return [average_lat, average_long]
  end

  def reply_tweet_options(tweet, nearest)
    { lat: nearest['lat'],
      long: nearest['lon'],
      display_coordinates: 'true',
      in_reply_to_status_id: tweet.id }
  end

  def reply_tweet_text(tweet, nearest)
    "@#{tweet.user.screen_name} \"#{nearest['title']}\" #{google_maps_link(nearest)}"
  end

  def google_maps_link(nearest)
    "https://www.google.com/maps/place/#{nearest['lat']},#{nearest['lon']}"
  end

  def update(text, options)
    client.update!(text, options)
  end
end
