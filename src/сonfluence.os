///////////////////////////////////////////////////////////////////
//
// Модуль интеграции с Confluence (https://ru.atlassian.com/software/confluence)
//
// (с) BIA Technologies, LLC	
//
///////////////////////////////////////////////////////////////////

#Использовать json

///////////////////////////////////////////////////////////////////

// ОписаниеПодключения
//	Создает структуру с набором параметров подключения.
//	Созданная структура в дальнейшем используется для всех операций
// 
// Параметры:
//  АдресСервера  	- Строка - Адрес (URL) сервера confluence. Например "https://conflunece.mydomain.ru"
//  Пользователь	- Строка - Имя пользователя для покдлючения
//  Пароль			- Строка - Пароль пользователя для подключения
//
// Возвращаемое значение:
//   Структура	- описание подключения
//	{
//		Пользователь,
//		Пароль,
//		АдресСервера
//	} 
//
Функция ОписаниеПодключения(АдресСервера = "", Пользователь = "", Пароль = "") Экспорт
	
	ПараметрыПодключения = Новый Структура;
	ПараметрыПодключения.Вставить("Пользователь", Пользователь);
	ПараметрыПодключения.Вставить("Пароль", Пароль);
	ПараметрыПодключения.Вставить("АдресСервера", АдресСервера);
	
	Возврат ПараметрыПодключения;
	
КонецФункции // ОписаниеПодключения()

///////////////////////////////////////////////////////////////////
// СТРАНИЦЫ
///////////////////////////////////////////////////////////////////

// НайтиСтраницуПоИмени
//	Ищет страницу в указанном пространстве по имени
// 
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Имя искомой страницы в указанном пространстве
//
// Возвращаемое значение:
//   Строка   - Идентификатор найденной страницы. Если страница не найдена, то будет возвращена пустая строка
//
Функция НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы) Экспорт
	
	Идентификатор = "";
	
	URL = ПолучитьURLОперации(КодПространства, ИмяСтраницы);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено И Результат.Количество() Тогда
			
			Результат0 = Результат[0];
			Идентификатор = Результат0.Получить("id");
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка поиска страницы: " + КодПространства + "." + ИмяСтраницы + 
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // НайтиСтраницуПоИмени() 

// ВерсияСтраницыПоИдентификатору
//	По идентификатору страницы получает ее версию
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   Строка   - Версия страницы, если версии нет (как??), то вернется пустая строка
//
Функция ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	Версия = "";
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("version");
		Если Результат <> Неопределено Тогда
			
			Версия = Результат.Получить("number");               			
			
		КонецЕсли; 
		
	Иначе
		
		ВызватьИсключение "Ошибка получения версии страницы:" + Идентификатор +  
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
	Возврат Версия;
	
КонецФункции // ВерсияСтраницыПоИдентификатору()

// ПодчиненныеСтраницыПоИдентификатору
//	Возвращает таблицу с подчиненными страницами
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  Идентификатор  			- Строка - Идентификатор страницы
//
// Возвращаемое значение:
//   ТаблицаЗначений   - Таблица с подчиненными страницами
//	{
//		Наименование 	- Строка - Наименование страницы
//		Идентификатор 	- Строка - Идентификатор страницы
//	}
//
Функция ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор) Экспорт
	
	ДочерниеСтраницы = Новый ТаблицаЗначений;
	ДочерниеСтраницы.Колонки.Добавить("Наименование");
	ДочерниеСтраницы.Колонки.Добавить("Идентификатор");
	
	URL = ПолучитьURLОперации(,, Идентификатор, "child/page");
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "GET", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ПарсерJSON = Новый ПарсерJSON;
		Ответ = ПарсерJSON.ПрочитатьJSON(РезультатЗапроса.Ответ);
		Результат = Ответ.Получить("results");
		Если Результат <> Неопределено Тогда			
			
			Для Каждого Запись Из Результат Цикл
				
				Дочка = ДочерниеСтраницы.Добавить();
				Дочка.Наименование = Запись.Получить("title");
				Дочка.Идентификатор = Запись.Получить("id");
				
			КонецЦикла               			
			
		КонецЕсли;
		
	Иначе
		
		ВызватьИсключение "Ошибка получения подчиненных страниц: " + Идентификатор + 
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
	Возврат ДочерниеСтраницы;
	
КонецФункции // ПодчиненныеСтраницыПоИдентификатору()

// СоздатьСтраницу
//	Создает новую страницу в указанном пространстве
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Содержимое  			- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя	- Строка - идентификатор родительской страницы
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной страницы
//
Функция СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "") Экспорт
	
	ИдентификаторСтраницы = "";
	
	URL = ПолучитьURLОперации();
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,
	|""space"": {""key"":""" + КодПространства + """},";
	
	Если Не ПустаяСтрока(ИдентификаторРодителя) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""ancestors"":[{""id"":" + ИдентификаторРодителя + "}],";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""body"": {""storage"":
	|	{
	|		""value"":""" + Содержимое + """
	|	,""representation"":""storage""
	|	}}
	|}";
	
	ИдентификаторСтраницы = "";
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "POST", URL);
	
	Если РезультатЗапроса.КодСостояния = 200 Тогда
		
		ИдентификаторСтраницы = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
	Иначе
		
		ВызватьИсключение "Ошибка создания страницы:" + КодПространства + "." + ИмяСтраницы + ""
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
	Возврат ИдентификаторСтраницы;
	
КонецФункции // СоздатьСтраницу() 

// ОбновитьСтраницу
//	Выполняет обновление существующей страницы
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Идентификатор			- Строка - идентификатор страницы. Если идентификатор указан, 
//										то при обновлении страницы наименование будет установлено из параметра ИмяСтраницы
//  Содержимое  			- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//
// Возвращаемое значение:
//   Строка   - Идентификатор обновленной страницы
//
Функция ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", Содержимое = "") Экспорт
	
	Если ПустаяСтрока(ИмяСтраницы) И ПустаяСтрока(Идентификатор) Тогда
		
		ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
		"Ответ: не указаны имя страниы и идентификатор";
		
	КонецЕсли;
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка обновления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;
	
	URL = ПолучитьURLОперации(,, Идентификатор);
	Версия = ВерсияСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);	
	Версия = Формат(Число(Версия) + 1, "ЧГ=");
	
	ТелоЗапроса = "
	|{
	|""type"": ""page"",
	|""title"": """ + ИмяСтраницы + """,";
	
	Если НЕ ПустаяСтрока(Содержимое) Тогда
		
		ТелоЗапроса = ТелоЗапроса + "
		|""body"": {""storage"":
		|	{
		|		""value"":""" + Содержимое + """
		|	,""representation"":""storage""
		|	}},";
		
	КонецЕсли;
	
	ТелоЗапроса = ТелоЗапроса + "
	|""version"":{""number"":" + Версия + "}
	|}";
	
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "PUT", URL, ТелоЗапроса);
	
	Если РезультатЗапроса.КодСостояния <> 200 Тогда
		
		ВызватьИсключение "Ошибка обновления страницы:" + КодПространства + "." + ИмяСтраницы + 
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // ОбновитьСтраницу()

// СоздатьСтраницуИлиОбновить
//	Создает страницу, если же страница существует, то обновляет
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Содержимое  			- Строка - Содержимое (тело) страницы. Текст должен обработан, т.е. экранированы спец символы для помещения в JSON
//  ИдентификаторРодителя	- Строка - идентификатор родительской страницы
//
// Возвращаемое значение:
//   Строка   - Идентификатор созданной / обновленной страницы
//
Функция СоздатьСтраницуИлиОбновить(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя = "")Экспорт
	
	Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
	
	Если Не ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = ОбновитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Идентификатор, Содержимое);

	Иначе

		Идентификатор = СоздатьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы, Содержимое, ИдентификаторРодителя);

	КонецЕсли;
	
	Возврат Идентификатор;
	
КонецФункции // СоздатьСтраницуИлиОбновить()

// УдалитьСтраницу
//	Удаляет существующую страницу 
//
// Параметры:
//  ПараметрыПодключения  	- Структура - Параметры подключения полученные методом ОписаниеПодключения
//  КодПространства  		- Строка - Код пространства confluence
//  ИмяСтраницы  			- Строка - Наименование страницы (заголовок)
//  Идентификатор			- Строка - Идентификатор страницы
//	УдалятьПодчиненные		- Булево - признак необходимости удаления подчиненых страниц.
//								Если данный параметр = ЛОЖЬ и есть подчиненные страницы, то удаление не будет выполнено
//								и будет вызвано исключение
//
Процедура УдалитьСтраницу(ПараметрыПодключения, КодПространства, ИмяСтраницы = "", Знач Идентификатор = "", УдалятьПодчиненные = ЛОЖЬ) Экспорт
	
	Если ПустаяСтрока(Идентификатор) Тогда
		
		Идентификатор = НайтиСтраницуПоИмени(ПараметрыПодключения, КодПространства, ИмяСтраницы);
		
		Если ПустаяСтрока(Идентификатор) Тогда
			
			ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: не найдена страница";
			
		КонецЕсли;
		
	КонецЕсли;

	ПодчиненныеСтраницы = ПодчиненныеСтраницыПоИдентификатору(ПараметрыПодключения, Идентификатор);

	Если ПодчиненныеСтраницы.Количество() И НЕ УдалятьПодчиненные Тогда
		
		ВызватьИсключение "Ошибка удаления страницы: " + КодПространства + "." + ИмяСтраницы +
			"Ответ: есть подчиненные страницы";

	КонецЕсли; 

	Для Каждого Страница Из ПодчиненныеСтраницы Цикл

		УдалитьСтраницу(ПараметрыПодключения, КодПространства, Страница.Наименование, Страница.Идентификатор, УдалятьПодчиненные); 

	КонецЦикла;
	
	URL = ПолучитьURLОперации(,, Идентификатор);
	РезультатЗапроса = ВыполнитьHTTPЗапрос(ПараметрыПодключения, "DELETE", URL);
	Если НЕ (РезультатЗапроса.КодСостояния = 200 И РезультатЗапроса.КодСостояния = 204) Тогда
			
		ВызватьИсключение "Ошибка обновления страницы:" + КодПространства + "." + ИмяСтраницы + 			
		"Запрос: " + URL + "
		|КодСостояния: " + РезультатЗапроса.КодСостояния + "
		|Ответ: " + РезультатЗапроса.Ответ;
		
	КонецЕсли;
	
КонецПроцедуры // УдалитьСтраницу()

///////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЙ ФУНКЦИОНАЛ
///////////////////////////////////////////////////////////////////

Функция ПолучитьURLОперации(КодПространства = "", ИмяСтраницы = "", Идентификатор = "", Операция = "")
	
	URLОперации = "rest/api/content/";
	КлючАвторизации = "?os_authType=basic";
	Если ПустаяСтрока(Идентификатор) Тогда
		
		URLОперации = URLОперации + КлючАвторизации;
		Если Не ПустаяСтрока(КодПространства) Тогда
			
			URLОперации = URLОперации + "&spaceKey=" + КодПространства;
			
		КонецЕсли;
		
		Если Не ПустаяСтрока(ИмяСтраницы) Тогда
			
			URLОперации = URLОперации + "&title=" + КодироватьСтроку(ИмяСтраницы, СпособКодированияСтроки.КодировкаURL);
			
		КонецЕсли;
		
	Иначе
		
		URLОперации = URLОперации + Идентификатор + ?(ПустаяСтрока(Операция), "", "/" + Операция) + "/" + КлючАвторизации;
		
	КонецЕсли;
	
	Возврат URLОперации;
	
КонецФункции // ПолучитьURLОперации() 

Функция ВыполнитьHTTPЗапрос(ПараметрыПодключения, Метод, URL, ТелоЗапроса = "")
	
	HTTPЗапрос = Новый HTTPЗапрос;
	HTTPЗапрос.Заголовки.Вставить("Content-Type", "application/json");
	HTTPЗапрос.Заголовки.Вставить("Accept", "application/json");
	
	HTTPЗапрос.АдресРесурса = URL;
	Если Не ПустаяСтрока(ТелоЗапроса) Тогда
		
		HTTPЗапрос.УстановитьТелоИзСтроки(ТелоЗапроса);
		
	КонецЕсли;
	
	HTTP = Новый HTTPСоединение(ПараметрыПодключения.АдресСервера,, ПараметрыПодключения.Пользователь, ПараметрыПодключения.Пароль);
	Если СтрСравнить(Метод, "GET") = 0 Тогда
		
		Ответ = HTTP.Получить(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "POST") = 0 Тогда
		
		Ответ = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "PUT") = 0 Тогда
		
		Ответ = HTTP.Записать(HTTPЗапрос);
		
	ИначеЕсли СтрСравнить(Метод, "DELETE") = 0 Тогда
		
		Ответ = HTTP.Удалить(HTTPЗапрос);
		
	Иначе
		
		ВызватьИсключение "Неизвестный метод: '" + Метод + "'"
		
	КонецЕсли;
	
	Возврат Новый Структура("Ответ, КодСостояния", Ответ.ПолучитьТелоКакСтроку(), Ответ.КодСостояния);
	
КонецФункции // ВыполнитьHTTPЗапрос()
