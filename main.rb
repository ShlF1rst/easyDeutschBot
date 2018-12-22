require 'telegram/bot'

TOKEN = '672978577:AAHnqKydhFpSdfhN7wHocDSn0Y5b7uo8DTc'

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		case message.text
		when '/start'
			bot.api.send_message(
				chat_id: message.chat.id,
				text: "Hello, #{message.from.first_name}")
		else
			bot.api.send_message( chat_id: message.chat.id,
				text: ":-(")
		end
	end
end