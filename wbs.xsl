<?xml version="1.0" encoding="UTF-8"?>

<!-- The MIT License:

Copyright 2021 - Derlidio Siqueira - Expoente Zero

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-->

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
          <script src="wbs.js"/>
      </head>
      <body>
        <h1><xsl:value-of select="project/name"/></h1>
        <div class="container">
          <xsl:apply-templates select="project/task"/>
        </div>
      </body>
      <script>add_behavior();</script>
    </html>
  </xsl:template>

  <xsl:template match="task">

     <!-- Compute the task's index based on it's position on the branch -->

    <xsl:variable name="task_index">
      <xsl:call-template name="index"/>
    </xsl:variable>

    <!-- ================================================================================================== -->
    <!-- Compute the number of "leaves" in this branch. Leaves are the tasks we actually work on, and wich  -->
    <!-- have their "percent-complete" updated (by hand, or by software interface) in the XML file.         -->
    <!-- If a task has sub-tasks, then it will be treated as a "node" in the "branch" (despite of the fact  -->
    <!-- that, for scripting purposes, it's internal type will still be "task"). Such nodes will have their -->
    <!-- percent-complete computed based on their leaves. Any number passed on the <percent> tag will be    -->
    <!-- ignored.                                                                                           -->
    <!-- ================================================================================================== -->

    <xsl:variable name="leaves" select="count(descendant::task[ count(task) = 0 ])"/>

    <!-- ============================================================================= -->
    <!-- Compute the number of tasks in each "status" (done, doing, paused, canceled). -->
    <!-- The status flags wich can be present on the XML are: "paused" and "canceled". -->
    <!-- The "pending", "doing", and "done" statuses are based on the task's percent   -->
    <!-- complete.                                                                     -->
    <!-- ============================================================================= -->

    <xsl:variable name="done" select="count(descendant::task[ (count(task) = 0) and (percent = 100) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="doing" select="count(descendant::task[ (count(task) = 0) and (percent &gt; 0 and percent &lt; 100) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="paused" select="count(descendant::task[ (count(task) = 0) and (percent &gt; 0 and percent &lt; 100) and (status = 'paused') ])"/>
    <xsl:variable name="canceled" select="count(descendant::task[ (count(task) = 0) and (status = 'canceled') ])"/>

    <!-- =================================================================================== -->
    <!-- Not all tasks of a project will have the same difficult level, so the user may want -->
    <!-- to apply "weights" to them. The <weight> tag must be used only on leaf tasks. It'll -->
    <!-- be spreaded upwards the task's brach accordingly.                                   -->
    <!-- =================================================================================== -->

    <xsl:variable name="weight_empty" select="count(descendant::task[ (count(task) = 0) and not(weight) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="weight_given" select="sum(descendant::task/weight[ (count(task) = 0) and ((status != 'canceled') or not(status)) ])"/>
    <xsl:variable name="weight_total" select="$weight_empty + $weight_given"/>

    <!-- =========================================================================== -->
    <!-- Computes the percent-complete of this task. If it's a node, sum the percent -->
    <!-- of it's leaves then takes the average (weighted percent).                   -->
    <!-- =========================================================================== -->

    <xsl:variable name="percent_sum">
      <xsl:call-template name="sum_percents">
        <xsl:with-param name="list" select="descendant::task[ (count(task) = 0) and ((status != 'canceled') or not(status)) ]"/>
        <xsl:with-param name="accumulated" select="0"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="percent_average">
        <xsl:choose>
          <xsl:when test="$leaves != 0">
            <!-- It's a branch. Use the average. -->
            <xsl:value-of select="format-number($percent_sum div $weight_total, '##0.##')"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- It's a leaf. Use the given percent. -->
            <xsl:choose>
              <xsl:when test="not(percent)">0</xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="format-number(percent, '##0.##')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ========================================== -->
    <!-- Compute the sum of hours on the leaf tasks -->
    <!-- ========================================== -->

    <xsl:variable name="hours_total" select="sum(descendant-or-self::task/hours[ (count(task) = 0) and ((status != 'canceled') or not(status)) ])"/>

    <!-- =================================== -->
    <!-- Let's start to process the branches -->
    <!-- =================================== -->

    <span class="branch" id="branch:{$task_index}">

      <span class="task" id="task:{$task_index}">

        <!-- =========================================== -->
        <!-- Draw the connectors above the task box/card -->
        <!-- =========================================== -->

        <xsl:choose>
          <xsl:when test="position() = 1"><div class="line_left"/></xsl:when>
          <xsl:when test="position() = last()"><div class="line_right"/></xsl:when>
          <xsl:otherwise>
            <div class="line_center">
              <div class="line_top"/>
            </div>
            </xsl:otherwise>
        </xsl:choose>

        <!-- ====================== -->
        <!-- The task info box/card -->
        <!-- ====================== -->

        <div class="box">

          <div class="card">
            
            <!-- ======================================== -->
            <!-- The task index (i.e.: 1, 1.1, 1.2, etc.) -->
            <!-- ======================================== -->

            <div> 

              <!-- Set attributes according to the task status -->

              <xsl:attribute name="class">
                index
                <xsl:choose>
                  <xsl:when test="status='canceled'">canceled</xsl:when>
                  <xsl:when test="status='paused'">paused</xsl:when>
                  <xsl:when test="$percent_average=100">completed</xsl:when>
                  <xsl:otherwise>index</xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>

              <xsl:value-of select="$task_index"/>

            </div>

            <!-- ================ -->
            <!-- The task's title -->
            <!-- ================ -->

            <div class="title">
              <xsl:if test="$hours_total &gt; 0">
                <span class="task_hours"><xsl:value-of select="$hours_total"/>h</span>
              </xsl:if>
              <span class="task_title"><xsl:value-of select="title"/></span>
            </div>

            <!-- ================================== -->
            <!-- Informative icons an resource name -->
            <!-- ================================== -->

            <div class="task_status">

              <div class="task_icon">

                <!-- ==================================================== -->
                <!-- If the task has descendants, give it a "branch" icon -->
                <!-- ===================================================  -->

                <xsl:if test="task">
                  <span class="material-icons-outlined task_icon toggler" id="toggler:{$task_index}">account_tree</span>
                </xsl:if>

                <!-- ============================================== -->
                <!-- If the task weight is greather than 1, show it -->
                <!-- ============================================== -->

                <xsl:if test="(weight &gt; 1) and not(task)">
                  <span class="task_weight">
                    <xsl:value-of select="weight"/>
                  </span>
                </xsl:if>

                <!-- ========================================================================= -->
                <!-- Select the task status icon based on the status flag and percent-complete -->
                <!-- ========================================================================= -->

                <span class="material-icons-outlined task_icon">
                  <xsl:choose>
                    <xsl:when test="status='canceled'">cancel</xsl:when> <!-- The task is canceled -->
                    <xsl:when test="($leaves != 0) and ($canceled = $leaves)">cancel</xsl:when> <!-- All tasks on the branch have been canceled -->
                    <xsl:when test="($leaves != 0) and ($leaves - $canceled = $done)">check_circle</xsl:when> <!-- All tasks on the branch are completed -->
                    <xsl:when test="($leaves !=0 ) and ($doing = $paused)">pause_circle</xsl:when> <!-- All ongoing tasks have benn paused -->
                    <xsl:when test="($leaves != 0) and ($doing != 0)">play_circle</xsl:when> <!-- There are ongoing tasks on the branch -->
                    <xsl:when test="percent = 100">check_circle</xsl:when> <!-- This is a completed leaf task -->
                    <xsl:when test="percent &gt; 0 and status='paused'">pause_circle</xsl:when> <!-- This is a paused leaf task -->
                    <xsl:when test="percent &gt; 0 and ($leaves = 0)">play_circle</xsl:when> <!-- This is an ongoing leaf task -->
                    <xsl:when test="$paused != 0 and $doing = $paused">pause_circle</xsl:when> <!-- All tasks on the branch have been paused -->
                    <xsl:when test="$doing != 0">play_circle</xsl:when> <!-- There are ongoing tasks on the branch -->
                    <xsl:otherwise>pending</xsl:otherwise> <!-- All tasks on the branch (or this task) are pending -->
                  </xsl:choose>
                </span>

              </div>

              <!-- ============= -->
              <!-- Resource name -->
              <!-- ============= -->

              <span class="task_resource"><xsl:value-of select="resource"/></span>

            </div>

            <!-- ================================= -->
            <!-- Odometer for the percent-complete -->
            <!-- ================================= -->

            <div class="task_meter">
              <div class="percent_fill">
                <xsl:attribute name="style">
                  width:<xsl:value-of select="$percent_average"/>%;
                </xsl:attribute>
                <div/>
              </div>
              <div class="percent"><xsl:value-of select="$percent_average"/>%</div>
            </div>

          </div>

        </div>

        <!-- ======================================================================================= -->
        <!-- If the task has sub-tasks, then it must have a connector at the bottom of it's box/card -->
        <!-- ======================================================================================= -->
        
        <xsl:if test="count(task) != 0">
          <div class="line_bottom"/>
        </xsl:if>

      </span>

      <!-- ====================================================== -->
      <!-- Apply the template for this task ramification (if any) -->
      <!-- ====================================================== -->

      <div class="ramification" id="ramification:{$task_index}">
        <xsl:apply-templates select="./task"/>
      </div>

    </span>

  </xsl:template>

  <!-- ============================== -->
  <!-- The index computation template -->
  <!-- ============================== -->

  <xsl:template name="index">      
    <xsl:variable name="order"><xsl:number count="task"/></xsl:variable>      
    <xsl:for-each select="..">
      <xsl:if test="name()!='project'"><xsl:call-template name="index"/>.</xsl:if>
    </xsl:for-each>
    <xsl:value-of select="$order"/>
  </xsl:template>

  <!-- ======================== -->
  <!-- The percent-sum template -->
  <!-- ======================== -->

  <xsl:template name="sum_percents">
    
    <xsl:param name="list"/>
    <xsl:param name="accumulated"/>

    <!-- Runs only if the "list" parameter has been passed -->

    <xsl:if test="$list">
            
      <!-- Captures the first list item -->

      <xsl:variable name="item" select="$list[position() = 1]"/>

      <!-- If the item has a <weight>, use it, otherwise assumes 1 -->

      <xsl:variable name="w">
        <xsl:choose>
          <xsl:when test="not($item/weight)">1</xsl:when>
          <xsl:otherwise><xsl:value-of select="$item/weight"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- The percent-complete must be between 0 and 100, inclusive -->

      <xsl:variable name="p">
        <xsl:choose>
          <xsl:when test="not($item/percent)">0</xsl:when>
          <xsl:when test="$item/percent &gt; 100">100</xsl:when>
          <xsl:otherwise><xsl:value-of select="$item/percent"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Computes the final task percent (weighted) -->

      <xsl:variable name="total" select="$accumulated + $p * $w"/>

      <!-- If we are at the last element of the list, then print the final value -->

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