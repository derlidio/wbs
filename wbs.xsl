<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="/">
    <html>
      <head>
          <title>WBS</title>
          <meta charset="UTF-8"/>
          <meta http-equiv="Pragma" content="no-cache"/>
          <meta http-equiv="Expires" content="-1"/>
          <meta http-equiv="CACHE-CONTROL" content="NO-CACHE"/>
          <link href="https://fonts.googleapis.com/css?family=Material+Icons|Material+Icons+Outlined" rel="stylesheet"/>
          <link rel="stylesheet" href="wbs.css"/>
      </head>
      <body>
        <h1><xsl:value-of select="project/name"/></h1>
        <div class="container">
          <xsl:apply-templates select="project/task"/>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="task">

    <!-- ================================================================================================= -->
    <!-- Computa a quantidade de "folhas" no ramo. Essas são as tarefas em que se trabalha (de verdade).   -->
    <!-- Ao ajustar (manualmente) o percentual de execução dessas tarefas os demais nós do ramo terão seus -->
    <!-- percentuais atualizados automaticamente (levando em conta o peso de cada tarefa).                 -->
    <!-- ================================================================================================= -->

    <xsl:variable name="leaf" select="count(descendant::task[ count(task) = 0 ])"/>

    <!-- ================================================================================================== -->
    <!-- Computa a quantidade de sub-tarefas em cada status (feita, a fazer, fazendo, pausada e cancelada). -->
    <!-- ================================================================================================== -->

    <xsl:variable name="done" select="count(descendant::task[ (count(task) = 0) and (percent = 100) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="doing" select="count(descendant::task[ (count(task) = 0) and (percent &gt; 0 and percent &lt; 100) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="paused" select="count(descendant::task[ (count(task) = 0) and (percent &gt; 0 and percent &lt; 100) and (status = 'paused') ])"/>
    <xsl:variable name="canceled" select="count(descendant::task[ (count(task) = 0) and (status = 'canceled') ])"/>

    <!-- ======================================= -->
    <!-- Calcula os pesos das folhas deste ramo. -->
    <!-- ======================================= -->

    <xsl:variable name="weight_empty" select="count(descendant::task[ (count(task) = 0) and not(weight) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="weight_given" select="sum(descendant::task/weight[ (count(task) = 0) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="weight_total" select="$weight_empty + $weight_given"/>

    <!-- ========================================================================= -->
    <!-- Computa o percentual total executado das sub-tarefas (folhas) deste ramo. -->
    <!-- ========================================================================= -->

    <xsl:variable name="weighted_percent">
      <xsl:call-template name="sum_percents">
        <xsl:with-param name="list" select="descendant::task[ (count(task) = 0) and ((status != 'canceled') or not(status)) ]"/>
        <xsl:with-param name="accumulated" select="0"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- ======================================== -->
    <!-- Computa a média ponderada do percentual. -->
    <!-- ======================================== -->

    <xsl:variable name="averaged_weight">
        <xsl:choose>
          <xsl:when test="$leaf != 0">
            <!-- É um nó. Utiliza média ponderada. -->
            <xsl:value-of select="format-number($weighted_percent div $weight_total, '##0.##')"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- É uma folha. Utiliza o percentual informado. -->
            <xsl:value-of select="format-number(percent, '##0.##')"/>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ========================================================================================= -->
    <!-- Uma ramificação da WBS. Pode conter outras ramificações (outros elementos do mesmo tipo). -->
    <!-- ========================================================================================= -->

    <div class="branch">

      <!-- ============================ -->
      <!-- Uma tarefa ou nó deste ramo. -->
      <!-- ============================ -->

      <div class="task">

        <!-- ================================================ -->
        <!-- Conectores na parte de cima do "card" da tarefa. -->
        <!-- ================================================ -->

        <xsl:choose>
          <xsl:when test="position() = 1"><div class="line_left"/></xsl:when>
          <xsl:when test="position() = last()"><div class="line_right"/></xsl:when>
          <xsl:otherwise>
            <div class="line_center">
              <div class="line_top"/>
            </div>
            </xsl:otherwise>
        </xsl:choose>

        <!-- ======================================== -->
        <!-- O "card" com informações sobre a tarefa. -->
        <!-- ======================================== -->

        <div class="box">

          <div class="card">
            
            <!-- ========================================== -->
            <!-- O índice da tarefa (ex: 1, 1.1, 1.2, etc.) -->
            <!-- ========================================== -->

            <div> 

              <!-- Os atributos do div são especificados conforme o status da tarefa -->

              <xsl:attribute name="class">
                index
                <xsl:choose>
                  <xsl:when test="status='canceled'">canceled</xsl:when>
                  <xsl:when test="status='paused'">paused</xsl:when>
                  <xsl:when test="$averaged_weight=100">completed</xsl:when>
                  <xsl:otherwise>index</xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <!-- O índice é composto dinamicamente conforme a posição da tarefa na árvore -->

              <xsl:call-template name="index"/>

            </div>

            <!-- =================== -->
            <!-- O título da tarefa. -->
            <!-- =================== -->

            <div class="task_title">
              <xsl:value-of select="title"/>
            </div>

            <!-- =================================== -->
            <!-- Ícones de status e nome do recurso. -->
            <!-- =================================== -->

            <div class="task_status">

              <div class="task_icon">

                <!-- ================================================================================= -->
                <!-- Quando a tarefa possuir descendentes (sub-tarefas), exibe um ícone informativo.   -->
                <!-- Este ícone também será utilizado no comportamento de "abrir/fechar" a ramificação -->
                <!-- ================================================================================= -->

                <xsl:if test="task">
                  <span class="material-icons-outlined task_icon">account_tree</span>
                </xsl:if>

                <!-- =================================================== -->
                <!-- Se o peso for maior que 1, exibe um box informativo -->
                <!-- =================================================== -->

                <xsl:if test="(weight &gt; 1) and not(task)">
                  <span class="task_weight">
                    <xsl:value-of select="weight"/>
                  </span>
                </xsl:if>

                <!-- =============================================================================== -->
                <!-- Seleciona o ícone a exibir conforme o status e percentual de execução da tarefa -->
                <!-- =============================================================================== -->

                <span class="material-icons-outlined task_icon">
                  <xsl:choose>
                    <xsl:when test="status='canceled'">cancel</xsl:when> <!-- A tarefa foi cancelada -->
                    <xsl:when test="($leaf != 0) and ($canceled = $leaf)">cancel</xsl:when> <!-- Todas as tarefas do ramo foram canceladas -->
                    <xsl:when test="($leaf != 0) and ($leaf - $canceled = $done)">check_circle</xsl:when> <!-- Todas as tarefas do ramo foram concluídas -->
                    <xsl:when test="($leaf !=0 ) and ($doing = $paused)">pause_circle</xsl:when> <!-- Todas as tarefas em execução no ramo foram pausadas -->
                    <xsl:when test="($leaf != 0) and ($doing != 0)">play_circle</xsl:when> <!-- Existem tarefas em execução nesse ramo -->
                    <xsl:when test="percent = 100">check_circle</xsl:when> <!-- É uma tarefa (folha) concluída -->
                    <xsl:when test="percent &gt; 0 and status='paused'">pause_circle</xsl:when> <!-- É uma tarefa (folha) pausada -->
                    <xsl:when test="percent &gt; 0 and ($leaf = 0)">play_circle</xsl:when> <!-- É uma tarefa (folha) em execução -->
                    <xsl:when test="$paused != 0 and $doing = $paused">pause_circle</xsl:when> <!-- Todas as tarefas em execução no ramo foram pausadas -->
                    <xsl:when test="$doing != 0">play_circle</xsl:when> <!-- Há tarefas em execução no ramo -->
                    <xsl:otherwise>pending</xsl:otherwise> <!-- Não há tarefas iniciadas no ramo -->
                  </xsl:choose>
                </span>

              </div>

              <!-- ========================================== -->
              <!-- Nome do recurso que vai executar a tarefa. -->
              <!-- ========================================== -->

              <span class="task_resource"><xsl:value-of select="resource"/></span>

            </div>

            <!-- ========================================================= -->
            <!-- Odômetro que marca o percentual executado da tarefa/ramo. -->
            <!-- ========================================================= -->

            <div class="task_meter">
              <div class="percent_fill">
                <xsl:attribute name="style">
                  width:<xsl:value-of select="$averaged_weight"/>%;
                </xsl:attribute>
                <div/>
              </div>
              <div class="percent"><xsl:value-of select="$averaged_weight"/>%</div>
            </div>

          </div>

        </div>

        <!-- ======================================================================================== -->
        <!-- Se a tarefa possuir sub-tarefas, cria uma linha (abaixo do card) conectando-a às filhas. -->
        <!-- ======================================================================================== -->
        
        <xsl:if test="count(task) != 0">
          <div class="line_bottom"/>
        </xsl:if>

      </div>

      <!-- ============================================================ -->
      <!-- Se houver sub-tarefas, aplica os templates (recursivamente). -->
      <!-- ============================================================ -->

      <xsl:apply-templates select="./task"/>      

    </div>

  </xsl:template>

  <!-- ========================================================= -->
  <!-- Template recursivo para cômputo do índice da tarefa ou nó -->
  <!-- ========================================================= -->

  <xsl:template name="index">      
    <xsl:variable name="order"><xsl:number count="task"/></xsl:variable>      
    <xsl:for-each select="..">
      <xsl:if test="name()!='project'"><xsl:call-template name="index"/>.</xsl:if>
    </xsl:for-each>
    <xsl:value-of select="$order"/>
  </xsl:template>

  <!-- ============================================================================== -->
  <!-- Template recursivo para cômputo do percentual de conclusão de um nó em um ramo -->
  <!-- ============================================================================== -->

  <xsl:template name="sum_percents">
    
    <xsl:param name="list"/>
    <xsl:param name="accumulated"/>

    <!-- Só executa o processo se tivermos recebido uma lista de tasks no parâmetro "list" -->

    <xsl:if test="$list">
            
      <!-- Captura o primeiro item da lista -->

      <xsl:variable name="item" select="$list[position() = 1]"/>

      <!-- Se um peso tiver sido especificado para o item, utiliza-o, caso contrário considera peso 1 -->

      <xsl:variable name="w">
        <xsl:choose>
          <xsl:when test="not($item/weight)">1</xsl:when>
          <xsl:otherwise><xsl:value-of select="$item/weight"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Normaliza o percentual de execução da tarefa (deve estar entre 0 e 100, inclusive) -->

      <xsl:variable name="p">
        <xsl:choose>
          <xsl:when test="not($item/percent)">0</xsl:when>
          <xsl:when test="$item/percent &gt; 100">100</xsl:when>
          <xsl:otherwise><xsl:value-of select="$item/percent"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Calcula o percentual da tarefa (levando em conta o peso) -->

      <xsl:variable name="total" select="$accumulated + $p * $w"/>

      <!-- Se a lista contiver apenas um elemento, então "printa" o valor acumulado (peso total) -->
      <!-- caso contrário, chama novamente o template passando as próximas tarefas da lista.     -->

      <xsl:choose>
        <xsl:when test="count($list) = 1">
          <xsl:value-of select="$total"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="sum_percents">
            <xsl:with-param name="list" select="$list[position() &gt; 1]"/>
            <xsl:with-param name="accumulated" select="$total"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:if>

  </xsl:template>

</xsl:stylesheet>