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
    tweets.each do |tweet|
      coordinates = tweet&.geo&.coordinates
      next unless coordinates
      nearest = Unphotographed.near(coordinates)
      pp reply_tweet_options(tweet, nearest)
      pp reply_tweet_text(tweet, nearest)
    end
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
