def login_fb()
	#login my fb
	#client = Selenium::WebDriver::Remote::Http::Default.new
  	#client.timeout = 180 # seconds
	browser = Selenium::WebDriver.for(:firefox) #:http_client => client)
	#browser = Selenium::WebDriver.for(:remote, :url => "http://localhost:8910")
	#browser.manage.timeouts.page_load = 2
	#browser.manage.timeouts.implicit_wait = 3  #Random.new.rand(3..10)
	browser.navigate.to "https://www.facebook.com/?stype=lo&jlou=AfdMSg6Kgrog3Qb1jKj20qno0Dz3ooGIaclbPKtC-hMIffGc-P2kizsIgZ5RAbtell3xURYGX497Q-qt9020eNtPxbP6nVlnZXj3ZVz7PnL0og&smuh=3839&lh=Ac9haStlCaeNkLtg"
	email_field = browser.find_element(:id, 'email')
	password_field = browser.find_element(:id, 'pass')
	buton_field = browser.find_element(:id, 'u_0_v')
	email_field.send_keys 'kaogaau@gmail.com'
	password_field.send_keys 'cksh1300473'
	buton_field.submit
	browser
end