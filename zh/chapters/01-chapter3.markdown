# 用Markdown来写 #
希望你已经照着上一章生成出了第一个Pdf文件，看到了一本蛮标准的书的样子。

这一章详细点介绍这是如何用Markdown写出来的。

首先简单介绍一下一本书的组成

## 标准书稿的组成 ##

一部完整的书稿，通常按顺序由封面、扉页、版权页（含内容简介）、序、前言、目录、正文（含图稿）、附录（可选项）、参考文献（可选项）、符号表（可选项）、索引（可选项）等组成。

详细请看电子出版社的《作译者手册》<http://www.phei.com.cn/wstg/zyzxz>

封面、扉页、版权页（含内容简介）封底一般有设计师用图形软件做出来单独印刷的。

序、前言、目录、正文（含图稿）、附录（可选项）都是标准提交格式写的。

参考文献（可选项）、符号表（可选项）、索引（可选项）一般应该是自动生成的。

## 怎么从Markdown到书 ##
前一章提到过，技术书籍对排版要求不高，不同级别的章节，代码显示和一些图示就可以了。因此有机会用文本的方式一一对应过去。

最[基本的Markdown](http://daringfireball.net/projects/markdown/)可以完成上面的功能了。

在Latex中设置好书的模板（`latex/template.tex`），如页眉、页脚、目录、颜色等等，一般有经验的人可以帮你搞定。

Pandoc软件会把Markdown文件转换成Latex格式，然后套上上面的模板。

`mkbok`是一个小工具，做了一些额外的定义和调整。

### Markdown扩展 ###

基本的Markdown功能不是很全（如没有脚注），因此可以考虑用一些Markdown的扩展。

由于会用Pandoc转换，我建议推荐用Pandoc的Markdown扩展<http://johnmacfarlane.net/pandoc/README.html>

你有兴趣也可以看看Github的<http://github.github.com/github-flavored-markdown/>

## 如何使用Markdown写书 ##
现在可以看看结构了。

	$ find zh
	zh/preface # 序和前言
	zh/chapters # 正文
	zh/appendix # 附录

### 标准章节 ###
每一章的第一行基本就是章节名字，应该只出现一次

	# 用Markdown来写 #

其他的小章节用`##`和`###`表示，最好不要有更多的层次。

### 序、前言、附录 ###
这和其他章节是一样的，只是在PDF的目录显示中章节号和计数不同。

### 页眉、页脚 ###
这是有Latex设定的，不需要Markdown参与。

### 目录 ###
这是有Latex自动生成的，不需要Markdown参与。

### 图片 ###
把图片放在`figures`目录中。

### 脚注 ###
这是Pandoc扩展Markdown才能支持

### 代码 ###
基本的Markdown用空四格的方式，不支持代码高亮显示。

	def main()
    	options = {
        	"build"=> "pdf",
	        "lang" => "zh",
	        "config"        => "latex/config.yml",
	        "template"      => "latex/template.tex",
	        "chapter-files" => "*/*.markdown",
	        "appendix-files"=> "*appendix/*.markdown",
	        "jeykll"        => false
	    }

我建议使用Pandoc扩展Markdown，它在生成的Epub和Html中支持代码高亮显示（还没搞定）

## 中文字体 ##
首先，我用的是Linux环境并且选用的是**UTF-8**的编码，而不是GBK，否则在github上显示会有问题，不了解这方面的朋友自己找找资料吧，够讲个把小时的。

在产生PDF时，一般建议内嵌中文字体的，但是真正能用的中文字体实际很少，极大多数是有版权的：

 * [文鼎](http://www.arphic.com.tw/)开放的四套字体（简报宋、细上海宋、简中楷、中楷），没有一点版权问题，是大部分的中文Linux的缺省安装。
 * [文泉驿](http://wenq.org/)的几套字体（微米黑、正黑、点阵宋体）是开放但是GPL性质的，所以不是随便可以商用的。
 * Adobe有两套开放字体（宋体、黑体）我认为是可以随便用的，忘了在哪里看到这个解释的了。

可以看看[Ubuntu免费中文字体](http://wiki.ubuntu.org.cn/免费中文字体)的介绍有个认识。

## 怎么选择对应字体 ##
一般缺省中文正文字体是宋体、细明体，对应英文Serif类的英文字体：Georgia、Times New Roman等。

标题和重要内容可以选楷体和黑体，对应英文Sans Serif类的英文字体：Arial、Tahoma、Verdana等

技术文章中常见的代码典型的等宽体用黑体，对应英文Monospace类的英文字体：Courier New等

所以对应的在[我的中文Latex配置](https://github.com/larrycai/sdcamp/blob/master/latex/config.yml)中可选的是：

 * font：文鼎的简报宋、细上海宋，文泉驿的点阵宋体，Adobe的宋体
 * bold: 文鼎的简中楷、中楷，文泉驿的微米黑、正黑，Adobe的黑体
 * mono: 文泉驿的微米黑、正黑，Adobe的黑体
