---
layout: post
title: "前端之路--SpringMVC+Angular 文件上传下载"
comments: true
tags: 技术与产品
---

最近一段时间一直在做一些前端相关的开发, 感觉是一如前端深似海啊, 对js是又爱又恨的. 方便, 快速是js和其他弱类型语言的优势; 但是谈到代码的可读性, 可维护性和模块封装的话, 那就是java, c++这种强类型语言的优势了, 用js写一个数百行的代码, 虽然加了注释但是感觉可读性还是比较差, 少了封装, 重复代码率也比较高.

最近项目中, 使用AngularJS和Bootstrap进行数据渲染和前端布局, 也遇到和解决了一些问题. 这次先把文件上传下载这块记录下来, 也算是知识备份. 

### 1. 文件上传

文件上传, HTML本身支持的文件上传不够优雅, 与Angular结合度比较低. github上关于这块的开源项目比较多, 最终选择了功能更为强大, 文档写的更细致的angular-file-upload.

#### 使用组件:

> [angularFileUpload](https://github.com/nervgh/angular-file-upload)

	1. 支持多文件批量上传
	
	2. 在文件添加后, 上传前, 上传后, 返回后等各个阶段提供回调函数. 我用它来做文件后缀名的检查, 比较好用.
	
	3. 支持图片的上传缩略图
	
	4. 支持拖拽上传
	
	5. API文档详细, 例子全面.

示例代码:

```html
<div class="row" ng-show="upload_classes == null">
	<div ng-show="uploader.isHTML5">
		<div>
			<input type="file" nv-file-select="" uploader="uploader"/>
		</div>
		<div ng-repeat="item in uploader.queue">
			<div class="progress" style="margin-bottom: 0;">
				<div class="progress-bar" role="progressbar"
					 ng-style="{ 'width': item.progress + '%' }"></div>
			</div>
		</div>
	</div>
	<button type="button" class="btn btn-success" ng-click="uploader.uploadAll()"
			ng-disabled="!uploader.getNotUploadedItems().length">
		<span class="glyphicon glyphicon-upload"></span> 上传
	</button>
</div>
```

```javascript
angular.module('pluginMgmt', ['ngDialog', 'angularFileUpload'])
    .controller("pluginMgmtCtrl", ['$scope', '$http', 'FileUploader', 'ngDialog', function ($scope, $http, FileUploader, ngDialog) {
		//显示上传浮层
        $scope.show_uploader = function () {
            $scope.creator_ref = ngDialog.open({
                className: 'ngdialog-theme-default dialogwidth600',
                template: 'plugin_uploader',
                scope: $scope,
                controller: ['$scope', function ($scope) {
                    //清空uploader
                    function clear_uploader() {
                        uploader.clearQueue();
                        uploader.destroy();
                    }

                    //检查是否是jar文件
                    uploader.onAfterAddingFile = function (fileItem) {
                        var name = fileItem.file.name;
                        if (name.indexOf(".jar") != name.length - 4) {
                            warn("请上传JAR文件");
                            clear_uploader();
                        }
                    };
                    //上传后展示
                    uploader.onCompleteItem = function (fileItem, response, status, headers) {
                        if (status == 200) {
                            uploader.clearQueue();
                            uploader.destroy();
                            $scope.upload_classes = response.result;
                            return;
                        } else if (status == 400) {
                            warn("提交数据有误:" + response.message);
                        } else if (status == 401) {
                            warn("操作失败，因为权限受限")
                        } else if (status == 403) {
                            warn(response.message)
                        } else if (status >= 500) {
                            warn("服务暂不可用");
                        } else {
                            warn("系统异常");
                        }
                        $scope.creator_ref.close();
                        clear_uploader();
                    };
                }]
            });
        };
	}
```

> SpringMVC

SpringMVC上传只是老生常谈的问题, 只是注意几个点就可以

	1. pom中添加[commons-fileupload]依赖
	
	2. bean.xml中需要增加 <bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver" /> 指定mvc使用multipartResolver
	
	3. 如果需要在上传文件的同时传参, 那么需要在js中加入formData即可, 注意formData是数组类型, API文档写的好! SpringMVC端改动不大

示例代码:

```java
@RequestMapping(value = "import", method = RequestMethod.POST)
    @ResponseBody
    public JsonResult processUpload(@RequestParam MultipartFile file,
                                    @RequestParam("project_id") Integer projectId,
                                    @RequestParam("pkg_id") Integer pkgId) throws Exception {
        ruleService.importRule(file.getInputStream(), projectId, pkgId);
        return JsonResult.create();
    }
```

```javascript
var uploader = $scope.uploader = new FileUploader({
	url: 'api/rule/import',
	formData: [{
		project_id: $scope.project_id,
		"pkg_id": $scope.my_tree.get_selected_branch().data.id
	}],
	queueLimit: 1 //only can add one item
});

uploader.onCompleteItem = function (fileItem, response, status, headers) {
	if (status == 200) {
		success("导入成功");
		$scope.my_tree_handler($scope.my_tree.get_selected_branch());
	} else {
		warn(response.message);
	}
	$scope.import_ref.close();
};

$scope.upload = function () {
	if (confirm("导入后会覆盖同名规则, 是否导入?")) {
		uploader.uploadAll();
	}
}
```

### 2. 文件下载

文件下载有几种方式, 

1. 比如前端知道文件名的, 可以直接使用window.open(url)方法获取文件进行下载, 这种情况比较少见, 除非是做下载服务器.

2. 根据参数生成文件, 将文件暂存在服务器上, 返回给前端一个文件名或者url, 然后前端通过iframe或者window.open(url)进行文件获取. 个人认为这种方法比较挫, 原因有2, (1)本来能一次干完的事儿分了两步做, (2)服务器的这种临时文件多需要清理, 否则会造成潜在隐患和问题(比如权限, 或者临时目录清理等).

3. 根据参数生成文件, 不生成临时文件, 直接将流写入Response的OutputStream, 如果是get请求则使用window.open(url)获取. 如果是post或者put请求, 那么需要在前端将流进行解析并输出, 这个时候需要使用[FileSaver](https://github.com/eligrey/FileSaver.js). 这是我最中意的办法, 节约服务器资源, 又比较优雅.

> 前端

```javascript
window.open('/api/rule/export?project_id=' + $scope.project_id + "&rule_names=" + $scope.rule_names);//get 请求

//post请求, 使用FileSaver.saveAs(), 直接将文件输出, 文件名从header里面拿
$scope.export = function() {
            $http({
                url: '/api/rule/export_dt',
                method: "POST",
                data: $.param({
                    project_id : $scope.project_id,
                    content: JSON.stringify($scope.decisionTable.toJson())
                }),
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                responseType: 'arraybuffer'
            }).success(function (data, status, headers, config) {
                var blob = new Blob([data], {type: "application/vnd.ms-excel"});
                saveAs(blob, [headers('Content-Disposition').replace(/attachment;fileName=/,"")]);
            }).error(function (data, status, headers, config) {
                //upload failed
            });
        };
```

> 后端

如果是普通文本, 则注意设置 Content-Disposition ,ContentEncoding, Content-Type, 因为没有临时文件生成, 所以content-length不能进行设置, 使用Transfer-Encoding: chunked 代替(如果两个都设置了, 浏览器会使用Transfer-Encoding). 

```java
@RequestMapping(value = "export")
    public void export(@RequestParam("project_id") Integer projectId, HttpServletResponse response) throws IOException {
        String filename = "rules_" + DateFormatUtils.ISO_DATE_FORMAT.format(new Date()) + ".txt";
        response.setCharacterEncoding("utf-8");
        response.setContentType(MediaType.APPLICATION_OCTET_STREAM_VALUE);
        response.setHeader("Content-Disposition", "attachment;filename=" + filename);
        response.setHeader("Transfer-Encoding", "chunked");
        IOUtils.copy(new StringReader(ruleService.export(projectId)), response.getOutputStream(), "utf-8");
    }
```

如果是其他文件格式, 比如excel, 则注意设置ContentType, Content-Disposition, Content-Transfer-Encoding:binary

```java
@RequestMapping(value = "export_dt", method = RequestMethod.POST)
    public void exportDecisionTable(@RequestParam("project_id") Integer projectId, @RequestParam("content") String content, HttpServletResponse response) throws IOException {
        String fileName = "decisionTable_" + DateFormatUtils.ISO_DATE_FORMAT.format(new Date()) + ".xls";
        response.setContentType("application/vnd.ms-excel");
        response.setHeader("Content-Disposition", "attachment;fileName=" + fileName);
        response.setHeader("Content-Transfer-Encoding", "binary");
        ruleService.exportDecisionTable(projectId, content, response.getOutputStream());
    }
```

### 参考资料:

> https://en.wikipedia.org/wiki/Chunked_transfer_encoding

> https://en.wikipedia.org/wiki/MIME

> http://www.w3.org/Protocols/rfc1341/5_Content-Transfer-Encoding.html

