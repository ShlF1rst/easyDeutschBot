require 'telegram/bot'
require 'pg'

TOKEN = '672978577:AAHnqKydhFpSdfhN7wHocDSn0Y5b7uo8DTc'

DB_TOKEN = 'postgres://iuowrrdbjarvap:83d39894f36baebf253f0d606e1a99abae3189f7921f4b49573282dcaf423eb4@ec2-54-235-247-209.compute-1.amazonaws.com:5432/d9a40bh9412n1n'



Telegram::Bot::Client.run(TOKEN) do |bot|
	con = PG.connect(DB_TOKEN)

	bot.listen do |message|
		case message.text
    when '/start'
    	rs = con.exec('SELECT * from public."USERS" WHERE user_id = $1;',[message.from.id])
			if (rs.cmd_status == 'SELECT 0')
				words_learned = 0
				con.exec('INSERT INTO public."USERS" (user_id, words_count) VALUES ($1, 0)',[message.from.id])
				bot.api.send_message(
				chat_id: message.chat.id,
				text: "Привет, #{message.from.first_name}! Похоже, что ты хочешь подучить английский? Я могу помочь тебе с этим!")				
				question = "Для начала давай выучим несколько слов?"
    			answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Давай начнём!', 'Я пока не хочу...'], one_time_keyboard: true)
    			bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
			end
		else
    			answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Выучим новые слова!', 'Хочу проверить уже пройденные!','Я пока не хочу...'], one_time_keyboard: true)
				bot.api.send_message(
				chat_id: message.chat.id,
				text: "Привет, #{message.from.first_name}! Рад снова видеть тебя. Чем займёмся сегодня?",reply_markup: answers)		

    when 'Давай начнём!', 'Следующее слово'

    	
   		question = 'London is a capital of which country?'
    	answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [ 'W', 'F'], one_time_keyboard: true)
   		bot.api.sendDocument(chat_id: message.chat.id, document: 'https://ssl.gstatic.com/dictionary/static/sounds/oxford/impossible--_us_1.mp3')
    	

  	when '/stop'
    	kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    	bot.api.send_message(chat_id: message.chat.id, text: 'Sorry to see you go :(', reply_markup: kb)
 
		
		else
			bot.api.send_message( chat_id: message.chat.id,
				text: "Введи /start, чтобы я начал диалог с тобой ;) ")
		end
	end
end