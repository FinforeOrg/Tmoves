require 'whatlanguage'
require 'language_detector'

TRANSLATOR = WhatLanguage.new(:all)
TRANSLATOR_GRAM = LanguageDetector.new
