import sys, os
import sphinx_rtd_theme

from sphinx.highlighting import lexers
from pygments.lexers.web import PhpLexer
from pygments.lexers.web import HtmlLexer
from pygments.lexers.web import JsonLexer

from datetime import datetime

lexers['php'] = PhpLexer(startinline=True)
lexers['php-annotations'] = PhpLexer(startinline=True)
lexers['html'] = HtmlLexer(startinline=True)
lexers['json'] = JsonLexer(startinline=True)

extensions = ['sphinx.ext.autodoc',
    'sphinx.ext.doctest',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx.ext.imgmath',
    'sphinx.ext.ifconfig',
    'sensio.sphinx.configurationblock']

source_suffix = '.md'
master_doc = 'index'

project = 'Warden'
copyright = '2019 by David Alger.'
author = 'David Alger'

version = ''
release = ''

exclude_patterns = ['_build']

html_theme = "sphinx_rtd_theme"
html_theme_path = [sphinx_rtd_theme.get_html_theme_path()]
html_show_sourcelink = False

html_static_path = ['_static']
templates_path = ['_templates']
html_extra_path = ['_redirects']
