import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/option
import gleam/result

const base_url = "0.0.0.0"

pub fn send_request(
  url: String,
  method: http.Method,
  headers: List(#(String, String)),
  body: String,
) {
  let request =
    request.new()
    |> request.set_host(base_url)
    |> request.set_port(8000)
    |> request.set_scheme(http.Http)
    |> request.set_path(url)
    |> request.set_method(method)
  let request = request.Request(..request, headers: headers)
  let final_request = case method == http.Get {
    True -> request.set_body(request, body)
    False -> {
      request.set_body(request, body)
    }
  }
  use resp <- result.try(httpc.send(final_request))
  Ok(resp)
}
