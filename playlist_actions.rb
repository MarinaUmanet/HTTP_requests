# frozen_string_literal: true

ADD_TRACKS_HERE = ['spotify:track:1vbn9fEyw1IYhqgZJdu9ZB', 'spotify:track:0e8nrvls4Qqv5Rfa2UhqmO',
                   'spotify:track:6kxaaIeowajN7w21PfMLbu'].freeze

def create_new_playlist(user_id, token)
  playlist_url    = "https://api.spotify.com/v1/users/#{user_id}/playlists"
  playlist_params = {
    'name': 'My new playlist',
    'public': false,
    'description': 'Awesome playlist',
    'collaborative': true
  }
  playlist_headers = {
    'Authorization': "Bearer #{token}",
    'Host': 'api.spotify.com'
  }

  playlist_response      = RestClient.post(playlist_url, playlist_params.to_json, playlist_headers)
  json_playlist_response = JSON.parse(playlist_response)
  json_playlist_response['id']
end

def add_tracks(playlist_id, token)
  tracks_url    = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  tracks_params = {
    'uris': ADD_TRACKS_HERE
  }
  tracks_headers = {
    'Authorization': "Bearer #{token}",
    'Host': 'api.spotify.com'
  }

  tracks_response      = RestClient.post(tracks_url, tracks_params.to_json, tracks_headers)
  json_tracks_response = JSON.parse(tracks_response)
  json_tracks_response['snapshot_id']
end

def reorder_tracks(playlist_id, snapshot_id, token)
  tracks_url     = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  reorder_params = {
    'range_start': 0,
    'insert_before': ADD_TRACKS_HERE.length,
    'snapshot_id': snapshot_id
  }

  tracks_headers = {
    'Authorization': "Bearer #{token}",
    'Host': 'api.spotify.com'
  }

  RestClient.put(tracks_url, reorder_params.to_json, tracks_headers)
end

def delete_tracks(playlist_id, snapshot_id, token)
  tracks_url    = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
  delete_params = {
    'tracks': [{
      'uri': ADD_TRACKS_HERE[0]
    }],
    'snapshot_id': snapshot_id
  }

  tracks_headers = {
    'Authorization': "Bearer #{token}",
    'Host': 'api.spotify.com'
  }

  RestClient::Request.execute(method: :delete, url: tracks_url, payload: delete_params.to_json,
                              headers: tracks_headers)
end
