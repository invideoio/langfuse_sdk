defmodule LangfuseSdk.Support.Auth do
  @public_key Application.compile_env!(:langfuse_sdk, :public_key)
  @secret_key Application.compile_env!(:langfuse_sdk, :secret_key)

  def put_auth_headers(%Req.Request{} = req) do
    Req.merge(req,
      headers: [
        {"Authorization", "Basic #{encode_credentials()}"},
        {"Content-Type", "application/json"}
      ]
    )
  end

  # Helper function to encode the credentials
  defp encode_credentials() do
    Base.encode64("#{@public_key}:#{@secret_key}")
  end
end
