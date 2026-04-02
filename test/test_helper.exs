Application.ensure_all_started(:inets)
Application.ensure_all_started(:ssl)

ExUnit.start()
