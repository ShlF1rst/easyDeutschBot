require 'telegram/bot'
require 'pg'

TOKEN = '789097081:AAENHZKLEIllcLCOatENkVgcNT8nZObDa5I'

DB_TOKEN = 'postgres://iuowrrdbjarvap:83d39894f36baebf253f0d606e1a99abae3189f7921f4b49573282dcaf423eb4@ec2-54-235-247-209.compute-1.amazonaws.com:5432/d9a40bh9412n1n'

TOTAL_COUNT = 10

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		con = PG.connect(DB_TOKEN)
    	rs = con.exec('SELECT * from public."USERS" WHERE user_id = $1;',[message.from.id])
    	words = con.exec('SELECT * from public."WORDS";')
		case message
			
	when Telegram::Bot::Types::CallbackQuery
		answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Продолжаем', 'Пока хватит'], one_time_keyboard: true)
    	if (message.data == '1') 
    		bot.api.send_message(
				chat_id: message.from.id,
				text: "Верно!",
				reply_markup: answers)
    	else
    			bot.api.send_message(
				chat_id: message.from.id,
				text: 'Неверно :( На самом деле оно переводится как '+message.data,
				reply_markup: answers)
		end

	when Telegram::Bot::Types::Message
		case message.text
    when '/start'
			if (rs.cmd_status == 'SELECT 0')
				con.exec('INSERT INTO public."USERS" (user_id, words_count) VALUES ($1, 0)',[message.from.id])
				bot.api.send_message(
				chat_id: message.chat.id,
				text: "Привет, #{message.from.first_name}! Похоже, что ты хочешь подучить английский? Я могу помочь тебе с этим!")				
				question = "Для начала давай выучим несколько слов?"
    			answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Давай начнём!', 'Я пока не хочу...'], one_time_keyboard: true)
    			bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
			else
    			answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Выучим новые слова!', 'Хочу проверить уже пройденные!','Я пока не хочу...'], one_time_keyboard: true)
				bot.api.send_message(
				chat_id: message.chat.id,
				text: "Привет, #{message.from.first_name}! Рад снова видеть тебя. Чем займёмся сегодня?",reply_markup: answers)		
			end
			con.close
    when 'Давай начнём!', 'Следующее слово', 'Выучим новые слова!'
    	learned_word_num = rs.getvalue(0,1).to_i
    	new_word = words.getvalue(learned_word_num,0)
    	new_word_tr = words.getvalue(learned_word_num,1)
    	answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: ['Следующее слово', 'Пока хватит'], one_time_keyboard: true)
    	bot.api.send_message(
				chat_id: message.chat.id,
				text: "#{new_word} - #{new_word_tr}",
				reply_markup: answers)		
   		bot.api.sendDocument(chat_id: message.chat.id, document: 'packs.shtooka.net/eng-wcp-us/ogg/En-us-'+new_word.to_s+'.ogg', caption: 'Произношение слова '+new_word)
   		learned_word_num = (learned_word_num + 1) % TOTAL_COUNT
   		con.exec('UPDATE public."USERS" set words_count = $1 where user_id = $2',[learned_word_num,message.from.id])
    	
   		con.close
   	when 'Хочу проверить уже пройденные!', 'Продолжаем'
   		learned_word_num = rs.getvalue(0,1).to_i
   		word_id = rand(learned_word_num)
    	new_word = words.getvalue(word_id,0)
    	new_word_tr = words.getvalue(word_id,1)
    	k1id = word_id
    	k2id = word_id
    	k3id = word_id
    	while (k2id == word_id)
    		k2id = rand(learned_word_num)
    	end
    	while (k1id == word_id || k1id == k2id)
    		k1id = rand(learned_word_num)
    	end
    	while (k3id == word_id || k3id == k1id || k3id == k2id)
    		k3id = rand(learned_word_num)
    	end
    	
    	kb= [
    	Telegram::Bot::Types::InlineKeyboardButton.new(text: words.getvalue(k1id,1), callback_data: new_word_tr),
    	Telegram::Bot::Types::InlineKeyboardButton.new(text: words.getvalue(k2id,1), callback_data: new_word_tr),
    	Telegram::Bot::Types::InlineKeyboardButton.new(text: words.getvalue(k3id,1), callback_data: new_word_tr),
    	Telegram::Bot::Types::InlineKeyboardButton.new(text: new_word_tr, callback_data: '1')
    	]
    	mk = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.sort_by{ rand })
    	bot.api.send_message(
				chat_id: message.chat.id,
				text: "Как переводится слово #{new_word}?",
				reply_markup: mk)
    	con.close
  	when 'Пока хватит', 'Я пока не хочу...'
    	kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    	bot.api.send_message(chat_id: message.chat.id, text: 'Пока, я буду ждать твоего возвращения...')
 		con.close
		
		else
			bot.api.send_message( chat_id: message.chat.id,
				text: "Введи /start, чтобы я начал диалог с тобой ;) ")
			con.close
		end
	end
end
end