# Author : Tsukasa Matsuno
# LastUpdate : 2016/11/14

# トップディレクトリ以下、全ソースファイルとヘッダーファイルを検索して、
# 実行ファイルを生成する汎用makefile

# ビルド対象となるTOPディレクトリを指定
# 本ディレクトリ以下の全てのディレクトリとフォルダがビルド対象
TOP_DIR=$(HOME)/document/C_Student
# コンパイルに用いるアプリケーション
# 例 : gcc, g++, cc, clang
COMP_APP=gcc

# コンパイルコマンド定義
COMP_OPT=-g -c
# リンカーコマンド定義
LINK_OPT=-g -Wall -Wextra

# flymake(リアルタイム コンパイルエラーチェック)オプション
# flymake で検出する警告&エラーレベルを指定
FLYMAKE_OPT=-Wall -Wextra
#FLYMAKE_OPT=" "

# TOP_DIRで指定したディレクトリ以下の存在するファイルをビルドするため、
# 本makefileは任意の場所に配置して良い。
# TOP_DIR直下の「DEP」「OBJ」は、makefileで管理するディレクトリとなるため、
# ユーザが作成したファイルを配置しないこと。(cleanを実行すると削除する)
# ソースファイルの拡張子は「.c」にのみ対応。 ソースファイルは、
# main関数を含むmainファイルと、main関数を含まないlibファイルに分類。
# libファイルのオブジェクトファイルはOBJに配置される。
# mainファイルはオブジェクトファイルを生成せずに、
# ソースから直接実行ファイルを作成する。

# 【この行より下は編集しないこと】

#-----------------------------------------------------------------
# ビルドで使用する変数定義 
#-----------------------------------------------------------------

# 中間ファイルを出力するディレクトリを定義
# オブジェクトファイル出力先ディレクトリ
OBJ_DIR=$(TOP_DIR)/OBJ
# 依存関係ファイルとログファイルの出力先ディレクトリ
DEP_DIR=$(TOP_DIR)/DEP
# 出力先ディレクトリをmkdir
$(shell [ -d $(OBJ_DIR) ] || mkdir -p  $(OBJ_DIR))
$(shell [ -d $(DEP_DIR) ] || mkdir -p  $(DEP_DIR))
# ビルドに使う中間ファイルを作成
# TOPディレクトリ以下に存在する全ての.c拡張子ファイルのパスを保存
OUTFILE_ALL_C=$(DEP_DIR)/all_source_list.txt

# TOPディレクトリ以下に存在する全ての.c拡張子ファイルを検索
ALL_SOURCE=$(shell find $(TOP_DIR) -type f -name "*.c" 2> /dev/null )
$(shell echo $(ALL_SOURCE) | sed 's/ /\n/g' > $(OUTFILE_ALL_C))
# カレントディレクトリ以下に存在する全ての.cファイルを検索
CURRENT_SOURCE=$(shell find $(PWD) -type f -name "*.c" 2> /dev/null )
# 全ての.cファイルをmain関数を含む物と含まない物に分ける
STR_MAIN="main("
# main関数を含む物を抽出する(mainファイル)
MAIN_C_SOURCE=$(shell grep $(STR_MAIN) -l $(CURRENT_SOURCE))
# main関数を含まない物を抽出する(libファイル)
LIB_C_SOURCE=$(shell grep $(STR_MAIN) -L $(ALL_SOURCE))

# コンパイラの-Iオプション用変数INC_OPTを作る
# TOPディレクトリ以下に存在する全ての.c拡張子ファイルを検索
ALL_HEAD_F=$(shell find $(TOP_DIR) -type f -name "*.h" 2> /dev/null )
# 検索結果からディレクトリ部分の文字列を抽出
ALL_HEAD_D=$(dir $(ALL_HEAD_F))
# ディレクトリの重複を削除するため、sort|uniqに投げる
# sortは行単位でしか行えないため、半角スペースを改行に置換する
INC_DIR=$(shell echo $(ALL_HEAD_D) | sed 's/ /\n/g'| sort | uniq )
# インクルードオプションである「-I」を付与
INC_OPT=$(addprefix -I, $(INC_DIR))

# ヘッダーファイル依存関係
# TOPディレクトリ以下に存在する全ての.d拡張子ファイルを検索
ALL_DEPT=$(shell find $(TOP_DIR) -type f -name "*.d" 2> /dev/null )

# 実行ファイルリスト作成
# 実行ファイルには拡張子をつけない
MAIN_EXE=$(basename $(MAIN_C_SOURCE))
# mainファイルのオブジェクトファイルを定義
MAIN_OBJ=$(addprefix $(OBJ_DIR)/, $(notdir $(MAIN_C_SOURCE:%.c=%.o)))
# libファイルのオブジェクトのオブジェクトファイルを定義
LIB_OBJ=$(addprefix $(OBJ_DIR)/, $(notdir $(LIB_C_SOURCE:%.c=%.o)))

CUR_SRCS=$(shell find . -type f -name "*.c" 2> /dev/null )
CUR_TSTS=$(CUR_SRCS:.c=)
#-----------------------------------------------------------------
# ビルドコマンド
# Hint : コマンドの先頭に@を付けると画面にコマンドを出力しない
#-----------------------------------------------------------------
.PHONY: all clean tags inc check-syntax

all:$(MAIN_EXE)

#-----------------------------------------------------------------
# リンクコマンド
# 実行ファイルを作成する
#-----------------------------------------------------------------
# カレントディレクトリに含まれる(再帰的)全mainファイルをコンパイル＆リンク
$(MAIN_EXE) : % : %.c $(LIB_OBJ)
	@echo $(COMP_APP) $(LINK_OPT) -MMD -MF demp.tmp -o $@  $<  $(LIB_OBJ) $(INC_OPT) >  linker.log
	$(COMP_APP) $(LINK_OPT) -MMD -MF demp.tmp -o $@ $<  $(LIB_OBJ) $(INC_OPT) 2>&1 | tee build_result.log
	@mv -f demp.tmp $(DEP_DIR)/$(notdir $(<:%.c=%.d))
	@cat linker.log >> $(DEP_DIR)/$(notdir $@).log; cat build_result.log >> $(DEP_DIR)/$(notdir $@).log; 
	@rm -fr linker.log build_result.log demp.tmp

# 個別に実行ファイルを指定した場合のコンパイル＆リンク
# 相対パスで指定した場合の関係を記載している
$(CUR_TSTS) : % : %.c $(LIB_OBJ)
	@echo $(COMP_APP) $(LINK_OPT) -MMD -MF demp.tmp -o $@  $<  $(LIB_OBJ) $(INC_OPT) >  linker.log
	$(COMP_APP) $(LINK_OPT) -MMD -MF demp.tmp -o $@ $<  $(LIB_OBJ) $(INC_OPT) 2>&1 | tee build_result.log
	@sed "s!$@!$(PWD)/$@!g"  demp.tmp > $(<:%.c=%.d) 
	@mv -f $(<:%.c=%.d)  $(DEP_DIR)
	@cat linker.log >> $(DEP_DIR)/$(notdir $@).log; cat build_result.log >> $(DEP_DIR)/$(notdir $@).log; 
	@rm -fr linker.log build_result.log demp.tmp

#-----------------------------------------------------------------
# コンパイルコマンド
# オブジェクトファイルを作成する
#-----------------------------------------------------------------
# libファイルをコンパイルするコマンド
# コンパイルによって生成したオブジェクトファイルはOBJディレクトリに格納する
$(LIB_OBJ) : %.o : $(shell cat $(OUTFILE_ALL_C) | grep %.c )
	@echo $(COMP_APP) $(COMP_OPT) -c  -o $@ -MMD -MF demp.tmp $(shell cat $(OUTFILE_ALL_C) | grep  $(notdir $(@:%.o=%.c))) $(INC_OPT) > complog.txt
	$(COMP_APP) $(COMP_OPT) -c -o $@ -MMD -MF demp.tmp $(shell cat $(OUTFILE_ALL_C) | grep  $(notdir $(@:%.o=%.c))) $(INC_OPT) 2>&1 | tee build_result.log
	@mv -f demp.tmp $(DEP_DIR)/$(notdir $(@:%.o=%.d))
	@cat build_result.log >> complog.txt; rm -fr build_result.log
	@mv -f complog.txt $(DEP_DIR)/$(notdir $(@:%.o=%.log))

# ヘッダーファイルの依存関係ファイルを読み込む
-include $(ALL_DEPT)

#-----------------------------------------------------------------
# cleanコマンド
#-----------------------------------------------------------------
clean :
	rm -fr $(OBJ_DIR) $(DEP_DIR) 
	rm -fr $(MAIN_EXE)
	find $(TOP_DIR) -type f -name "TAGS" | xargs rm -f

#-----------------------------------------------------------------
# tagsコマンド
#-----------------------------------------------------------------
tags :
	@ctags -Re --languages=c,c++ $(TOP_DIR)
	@cp TAGS $(TOP_DIR)/ 
	@echo "make TAGS : ./TAGS " $(TOP_DIR)/TAGS

inc :
	@echo $(INC_OPT)

check-syntax :
	$(COMP_APP) $(INC_OPT) $(FLYMAKE_OPT) -Wall -Wextra -fsyntax-only $(CHK_SOURCES)
