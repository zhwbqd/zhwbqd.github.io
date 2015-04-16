---
layout: post
title: "利用Highcharts绘制treemap"
comments: true
tags: JS
---

用过Sonar的同学都会对它的treemap印象深刻(这个Treemap不是指那个基于红黑树的数据结构哈), Treemap的好处是可以将大批量数据进行分层次展示, 清晰而且交互感强.

![架构图](/post_imgs/sonarTreeMap.jpg)

[知乎上有个专栏专门介绍Treemap及它的一些应用](http://zhuanlan.zhihu.com/datavis/19894525)

---------------------------

Treemap目前的开源类库有D3和Highcharts, D3进行Treemap的编写更加底层也更加灵活, 更接近于svg的风格. D3中相关API可以参考[官方文档Treemap-Layout](https://github.com/mbostock/d3/wiki/Treemap-Layout);

对于习惯使用highcharts的同学们, 可能会更习惯于highcharts提供的treemap api. 相比于D3的API, Highcharts的文档更加友好, 而且提供多种在线示例, 可以简单的上手, 相关的配置跟highcharts大同小异, 看上去就有亲切感. 这里是Highcharts的[Treemap API](http://www.highcharts.com/docs/chart-and-series-types/treemap)

------------------------------

数据可视化, 数据和可视化的配置分开来说

#### 数据方面

Treemap的数据这两个元素是必须的 [{'name':'xxx', 'value': 123}], treemap的算法主要是根据value的值进行一个块大小的分配.

#### 可视化方面

* Treemap可分多层, 可以展示数据直接的包含关系. 比如: 报告每个部门的完成数量, 点击每个部门可以看到每个小组的情况, 点击小组可以看到每个人的情况.

> 在数据层面需要比默认的多两个元素 id 和 parent, id加在每个数据上, parent加在子数据上指定父数据的 id
 [{'id':'1','name':'parent', 'value': 123},{{'id':'2','name':'child', 'value': 123,'parent':'1'}}]

[官方的例子在这边](http://jsfiddle.net/gh/get/jquery/1.7.2/highslide-software/highcharts.com/tree/master/samples/highcharts/demo/treemap-large-dataset)

* Treemap可对每个数据指定颜色, 也可以根据 value 值的大小自己进行颜色过渡

+ 自己指定颜色:

> 在数据层面需要比默认的多一个元素 color, 可用rgb(xxx,xxx,xxx), 也可使用十六进制颜色值(#FFFFFF), 也可使用highcharts的随机色(Highcharts.getOptions().colors[xxx])
 [{'id':'1','name':'parent', 'value': 123, 'color':'rgb(199,199,199)'},{{'id':'2','name':'child', 'value': 123,'parent':'1','color':'#FFFFFF'}}]

+ 使用渐变过渡:

> 数据层面增加colorValue元素, 值域是整数, 另外需要引入heatmap.js. *但如果数据有层级, 且指定了渐变过渡, 那么展示会有问题.* **另外, treemap的子元素颜色会覆盖父元素颜色, 所以这块要考虑清楚**
 
[官方的例子在这边](http://jsfiddle.net/gh/get/jquery/1.7.2/highslide-software/highcharts.com/tree/master/samples/highcharts/demo/treemap-coloraxis)


* Treemap可对展示的文字和tooltips进行个性配置. 其实主要就是修改显示内容, 字体大小, 颜色等

> 对于dataLabels的配置在[这里](http://api.highcharts.com/highcharts#plotOptions.treemap.dataLabels)
> 对于tooltip的配置在[这里](http://api.highcharts.com/highcharts#plotOptions.treemap.tooltip)

掌握了这三条, 我们就可以制作出一个满足大部分需求的treemap了

----------------------------------------

下面是一个完整的例子, 我在重要位置加了注释, 效果展示在[这里](https://jsfiddle.net/zhwbqd/6wngv8xx/3/)

```javascript
function treemap (data) {

    var data_list=[];

    for(var i in data){
        var rule = data[i];
        var bp_element={ //构建父数据
            id: "bp_" + rule.bpId, //id请保证唯一性
            name:rule.bpDesc,
            value:rule.allCount, 
            color:judge_color(parseInt(rule.fireRate)), //通过比率进行颜色的变换
            rate: rule.fireRate + '%'
        };
        data_list.push(bp_element);

        var stats = rule.weeklyRuleStats; 
        for(var j in  stats){//构建子数据
            var subrule = stats[j];
            var rule_element={
                id:bp_element.id+"_rule_"+ j, //id的唯一性
                name:subrule.ruleName,
                value:subrule.fireCount,
                parent:bp_element.id, //父数据的id
                rate: subrule.proportion + '%'//子元素不设置颜色, 否则父元素的颜色会被覆盖
            };
            data_list.push(rule_element);
        }
    }

    var chart = new Highcharts.Chart({
        chart: {
            renderTo: 'treemap_container' //页面div的id
        },
        series: [{
            type: "treemap", 
            layoutAlgorithm: 'squarified', //展示算法
            allowDrillToNode: true, //是否可以点击进入子数据
            dataLabels: {
                enabled: false
            },
            levelIsConstant: false,
            levels: [{
                level: 1, //第一层数据的相关配置
                dataLabels: {
                    enabled: true,
                    style: {
                        fontSize: '15px'
                    }
                },
                borderWidth: 3
            },
                {
                    level: 2, //第二层数据的相关配置
                    dataLabels: {
                        enabled: false
                    },
                    borderWidth: 1
                }],
            data: data_list
        }],
        tooltip: {
            pointFormatter: function(){ //鼠标滑过后的tooltip展示
                if (!this.parent) {
                    return '<b>名称 : '+ this.name + '</b> ' +
                        '<br/><b>请求数 : ' + this.value + '</b> <br/>' +
                        '<b>拦截率 : ' + this.rate + '</b><br/>'
                }else {
                    return '<b>子规则名称 : '+ this.name + '</b> ' +
                        '<br/><b>拦截数 : ' + this.value + '</b> <br/>' +
                        '<b>拦截占比 : ' + this.rate + '</b><br/>'
                }

            }
        },
        subtitle: {
            text: 'Size: 请求数, Color: 拦截率'
        },
        title: {
            text: '规则拦截显示'
        }
    });
}

function judge_color(rate){
    var colors = ['#0dae00','#52c000','#72c000','#b2c000','#777777'];
    return colors[ 4 - parseInt(rate/20)]
}
```


 

