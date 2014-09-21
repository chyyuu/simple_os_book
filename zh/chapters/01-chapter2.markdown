# 基础知识:10分钟写出第一本书 #
## 先从Pro Git说起 ##

如果你了解Git，或者想了解Git。那么你就应该知道[Pro Git](http://progit.org/)，它是Git的书中写得最好的一本（至少是之一），可是你是否知道它有网络中文版，而且能在iPad上极其漂亮得阅读。并且是免费的，不是盗版的免费！如果你想要最新的，你甚至可以自己生成它。哈哈，我就是这么干的。

这一切就归功于开源社区和它后面用到的技术。

###开源书###
这里我不用多讲，开源书就像其他的开源产品（如维基百科）一样，只要是开放的，社区就有人会贡献。[Pro Git](http://progit.org/)的作者Scott很慷慨得把书的内容全部共享在[github/progit](http://github.com/progit/progit)库中，使用得是[CC BY-NC-SA 3.0](http://creativecommons.org/licenses/by-nc-sa/3.0/us/)。

Scott只负责英文版，其他许许多多语言的翻译都是社区贡献的，中文翻译相当有质量，你可以在线读[Pro Git中文版](http://progit.org/book/zh/)。

### 开源技术生成电子书 ###
这本书不仅仅开源了内容，使用的技术也是开源的。让我们看看他是怎么做的。

### Markdown原始文件 ###
首先书的内容是用Markdown格式写的。Markdown格式的普及要归功于[Github](github.com)和[StackOverflow](http://stackoverflow.com/)。因为它们越来越流行，它们支持和使用的Markdown格式也越来越流行。这里要赞一个的是，国内的[图灵社区](http://www.ituring.com.cn/)也支持Markdown，用起来超级方便。

简单来说，Markdown格式的文件看着像一般的文本文件，里面只是加了很少的格式标记，因此直接看Markdown的文本文件也不影响理解，这种格式也有很多工具帮你去转化，而且很容易自动化解决。并且这些技术大多数是开源或免费的。

松本行弘在他的Ruby书中说的好，想象一下几十年后，你是否还能找到软件来打开你的Word老格式的文档，没有软件支持，你的文档也就难以使用了。文本文件就没有这个问题。

你可以直接看一下【Pro Git】的[“第一章 介绍” 的Markdown原始文件](https://raw.github.com/progit/progit/master/zh/01-introduction/01-chapter1.markdown)，顺便看看github自动生成的简单[“第一章 介绍” 的html](https://github.com/progit/progit/blob/master/zh/01-introduction/01-chapter1.markdown)。

## 产生电子书 ##
### PDF格式 ###
为了能达到出版的质量，Latex是一个常用的格式，PDF也能很容易地转换出来，有关Latex，自己看看参考链接学习吧。

[Pandoc](http://johnmacfarlane.net/pandoc/)能帮着从Markdown转换出Latex格式，然后再用[TexLive](http://www.tug.org/texlive/)软件中的`xelatex`转成PDF格式。  

![从makedown到pdf](0101pdf.jpg)


### Epub/Mobi格式 ###
Ruby的[rdiscount](https://github.com/rtomayko/rdiscount)能帮你从markdown转成html格式，然后有[Calibre](calibre)附带的命令`ebook-convert`生成最终的`.mobi` (Kindle) 和 `.epub` (iPad)。

从1.8版本开始，Pandoc也开始支持生成Epub格式了。

## 工作环境 ##
你只需要一台Linux机器（虚拟机就可以了）和熟悉简单的Linux命令就可以试验了。有Git和Ruby的知识那就更方便了。

我用的试验环境是Ubuntu Oneiric (11.10）

### 下载中文开源书 ###
很简单，`git clone`一下这本书就可以了，下载它的源文件包我觉得还是烦了点。
    
	$ git clone git@github.com/larrycai/kaiyuanbook.git
    
### PDF格式 ###
生成PDF是一个比较复杂的东西，[pandoc](http://johnmacfarlane.net/pandoc/)用Ubuntu库里1.8.x版本，[TexLive](http://www.tug.org/texlive/)用缺省Ubuntu源里的2009版也够了。当然也可下载最新的[TexLive](http://www.tug.org/texlive/)包安装，并配置到搜索路径中。
    
	$ sudo apt-get install ruby1.9.1
	$ sudo apt-get install pandoc
	$ sudo apt-get install texlive-xetex
	$ sudo apt-get install texlive-latex-recommended # 主要的Latex包
	$ sudo apt-get install texlive-latex-extra # titlesec包，先不用知道

因为是中文PDF，需要把字体嵌入在文件中，因此需要安装字体文件，幸运的是在源里有不错的字体。

	$ sudo apt-get install ttf-arphic-gbsn00lp ttf-arphic-ukai # 文鼎字体
	$ sudo apt-get install ttf-wqy-microhei ttf-wqy-zenhei # 文泉驿字体
    
现在你就可以用`mkbok`命令生成Pdf文件了，`mkbok`会自动调用Pandoc和Latex工具生成Pdf、Html、Epub格式。

    $ ./mkbok	
    
怎么样，打开看看Pdf文件，很漂亮了吧。

## 自己试试 ##
一定要做，搜索一下，改掉一些内容，再运行一遍。

好了，你可以把书扔到一遍，写你自己的书了。照样画葫芦，你行的。在下一章会对书的结构和怎么对应地用Markdown写进行详细地解释。
	
## 其他常用的格式 ##

计算机类图书对格式要求不是很多，图文、章节、源代码基本就够了，就算有些复杂公式，也可用图来显示。这也从理论上说明，它不需要复杂的格式。现在对这类技术书出版我的理解主要有几种：

 1. Microsoft的Word格式，虽然国内出版界如日中天，缺省就认它（对技术没追求，鄙视）。简单好学，但是不擅长自动化，是开源的死敌。
 2. Latex格式（就是Donald E. Knuth（高德纳）发明的，这是很棒的东西，特别适合学术类的各种复杂的公式等，不过学习曲线很高，直接写还是很有难度的。国内也只有几家学术期刊使用。
 3. Docbook格式是最有名的（从SGML演化过来？），Orielly和Pragmatic出版社缺省就用它，它能    很方便的转化出出版要的各种样式。如[Jenkins - the definition guide](http://www.wakaleo.com/books/jenkins-the-definitive-guide)开源书就是采用Docbook。但由于是XML格式，很多人不习惯，而且多人网上协作不是很方便。
 4. 通过蒋鑫的[Got Github](http://www.worldhello.net/gotgithub/)开源书，我也了解reStructureText也是和Markdown差不多纯文本的，也是蛮流行的。
 
## 参考 ##
 1. Pro Git: <http://progit.org/>
 2. LaTeX2e完全学习手册: <http://book.douban.com/subject/5450816/>


 
