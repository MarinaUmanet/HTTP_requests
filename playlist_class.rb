# frozen_string_literal: true

class Playlist
  attr_accessor :id,
                :name,
                :description,
                :owner_name,
                :spotify_url,
                :tracks,
                :playlist_id,
                :token

  def initialize(playlist_id, token)
    self.playlist_id = playlist_id
    self.token       = token
    self.id          = parse_playlist['id']
    self.name        = parse_playlist['name']
    self.description = parse_playlist['description']
    self.owner_name  = parse_playlist['owner']['display_name']
    self.spotify_url = parse_playlist['href']
    self.tracks      = []
  end

  def parse_playlist
    @get_playlist_url = "https://api.spotify.com/v1/playlists/#{playlist_id}"
    @playlist_headers = {
      'Authorization': "Bearer #{token}",
      'Host': 'api.spotify.com'
    }

    playlist_response = RestClient.get(@get_playlist_url, headers = @playlist_headers)
    JSON.parse(playlist_response)
  end

  def json_format
    {
      'name': name,
      'description': description,
      'owner_name': owner_name,
      'spotify_url': spotify_url,
      'id': id,
      'tracks': tracks
    }
  end
end
