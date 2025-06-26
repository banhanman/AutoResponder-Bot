require 'telegram/bot'
require 'yaml'

# Конфигурация
TOKEN = 'ВАШ_TELEGRAM_BOT_TOKEN'.freeze
RESPONSES_FILE = 'responses.yml'.freeze

# Загрузка правил ответов
RESPONSES = begin
  YAML.load_file(RESPONSES_FILE) if File.exist?(RESPONSES_FILE)
rescue StandardError
  {}
end || {
  'default' => 'Извините, я не понял ваш запрос. Попробуйте задать вопрос иначе.',
  'patterns' => {
    '\b(привет|здравствуй|хай|здорово)\b' => 'Привет! Чем могу помочь?',
    '\b(спасибо|благодарю)\b' => 'Всегда пожалуйста! 😊',
    '\b(пока|до свидания|прощай)\b' => 'До новых встреч! Не стесняйтесь обращаться снова.',
    '\b(как дела|как ты)\b' => 'У меня всё отлично, я же бот! А у вас?',
    '\b(бот|ты кто)\b' => 'Я умный автоответчик, созданный помогать вам!',
    '\b(помощь|команды)\b' => "Доступные команды:\n/start - Начало работы\n/help - Помощь\n/custom - Задать свой ответ"
  },
  'commands' => {
    '/start' => 'Добро пожаловать! Я ваш персональный автоответчик. Просто напишите сообщение, и я отвечу!',
    '/help' => 'Я отвечаю на сообщения по заданным правилам. Вы можете настроить меня через файл responses.yml',
    '/custom' => 'Вы использовали специальную команду!'
  },
  'media' => {
    'photo' => 'Отличное фото! Спасибо, что поделились 📸',
    'sticker' => 'Классный стикер! 😄',
    'document' => 'Файл получен, спасибо! 📄'
  }
}

# Сохранение шаблонов в файл
File.write(RESPONSES_FILE, RESPONSES.to_yaml) unless File.exist?(RESPONSES_FILE)

# Функция для поиска подходящего ответа
def find_response(message)
  text = message.text.to_s.downcase
  
  # Проверка команд
  if text.start_with?('/')
    command = text.split(' ').first
    return RESPONSES['commands'][command] if RESPONSES['commands'].key?(command)
  end
  
  # Проверка медиа
  return RESPONSES['media']['photo'] if message.photo
  return RESPONSES['media']['sticker'] if message.sticker
  return RESPONSES['media']['document'] if message.document
  
  # Проверка шаблонов
  RESPONSES['patterns'].each do |pattern, response|
    return response if text.match?(Regexp.new(pattern))
  end
  
  # Ответ по умолчанию
  RESPONSES['default']
end

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    begin
      response = find_response(message)
      
      # Отправка ответа
      bot.api.send_message(
        chat_id: message.chat.id,
        text: response,
        reply_to_message_id: message.message_id
      )
      
      # Логирование
      puts "[#{Time.now}] Ответ пользователю #{message.from.username}: #{response}"
    rescue StandardError => e
      puts "Ошибка: #{e.message}"
    end
  end
end
