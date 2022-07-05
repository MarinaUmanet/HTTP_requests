# frozen_string_literal: true

CLIENT_ID = '9d49db8c924444c1963b185bbbd66391'
CLIENT_SECRET = '19ec0af985d54c778974a45fe93b5741'
EMAIL = 'marinaumanet@gmail.com'
PASSWORD = '1234512345'
REDIRECT_URI = 'http://localhost:8888/callback'

def build_url
  url  = 'https://accounts.spotify.com/authorize'
  url += "?client_id=#{CLIENT_ID}"
  url += '&response_type=code'
  url += "&redirect_uri=#{REDIRECT_URI}"
  url += '&scope=user-read-private playlist-read-private playlist-modify-private playlist-read-collaborative'
end

def get_code(auth_url)
  browser     = Watir::Browser.new
  browser.goto(auth_url)
  login_field = browser.text_field(id: 'login-username')
  login_field.set(EMAIL)
  pass_field  = browser.text_field(id: 'login-password')
  pass_field.set(PASSWORD)

  browser.button(text: 'Log In').click
  # browser.button(:text => "Agree").click
  sleep 3
  uri = URI.parse(browser.url).to_s
  uri.split('code=').last
end

def get_token(code)
  encoded_client  = Base64.encode64("#{CLIENT_ID}"':'"#{CLIENT_SECRET}").delete("\n")
  token_url       = 'https://accounts.spotify.com/api/token'
  token_params = {
    'grant_type': 'authorization_code',
    'code': code,
    'redirect_uri': REDIRECT_URI
  }
  token_headers = {
    'Authorization': "Basic #{encoded_client}",
    'Content-Type': 'application/x-www-form-urlencoded'
  }

  response      = RestClient.post(token_url, token_params, token_headers)
  json_response = JSON.parse(response)
  json_response['access_token']
end

def get_user_id(token)
  user_id_url = 'https://api.spotify.com/v1/me'
  id_headers  = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': "Bearer #{token}"
  }

  response_id      = RestClient.get(user_id_url, id_headers)
  json_response_id = JSON.parse(response_id)
  json_response_id['id']
end
