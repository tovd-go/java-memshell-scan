<%@ page import="java.net.URL" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="com.sun.org.apache.bcel.internal.Repository" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.apache.catalina.core.StandardWrapper" %>
<%@ page import="java.lang.reflect.Method" %>
<%@ page import="java.util.concurrent.CopyOnWriteArrayList" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>tomcat-memshell-killer</title>
</head>
<body>
<center>
    <div>
        <%!
            public Object getStandardContext(HttpServletRequest request) throws NoSuchFieldException, IllegalAccessException {
                Object context = request.getSession().getServletContext();
                Field _context = context.getClass().getDeclaredField("context");
                _context.setAccessible(true);
                Object appContext = _context.get(context);
                Field __context = appContext.getClass().getDeclaredField("context");
                __context.setAccessible(true);
                Object standardContext = __context.get(appContext);
                return standardContext;
            }

            public HashMap<String, Object> getFilterConfig(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _filterConfigs = standardContext.getClass().getDeclaredField("filterConfigs");
                _filterConfigs.setAccessible(true);
                HashMap<String, Object> filterConfigs = (HashMap<String, Object>) _filterConfigs.get(standardContext);
                return filterConfigs;
            }

            // FilterMap[]
            public Object[] getFilterMaps(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _filterMaps = standardContext.getClass().getDeclaredField("filterMaps");
                _filterMaps.setAccessible(true);
                Object filterMaps = _filterMaps.get(standardContext);

                Object[] filterArray = null;
                try { // tomcat 789
                    Field _array = filterMaps.getClass().getDeclaredField("array");
                    _array.setAccessible(true);
                    filterArray = (Object[]) _array.get(filterMaps);
                } catch (Exception e) { // tomcat 6
                    filterArray = (Object[]) filterMaps;
                }

                return filterArray;
            }

            /**
             * ????????????,getFilterConfig()????????????2???
             * @param request
             * @param filterName
             * @throws Exception
             */
            public synchronized void deleteFilter(HttpServletRequest request, String filterName) throws Exception {
                Object standardContext = getStandardContext(request);
                // org.apache.catalina.core.StandardContext#removeFilterDef
                HashMap<String, Object> filterConfig = getFilterConfig(request);
                Object appFilterConfig = filterConfig.get(filterName);
                Field _filterDef = appFilterConfig.getClass().getDeclaredField("filterDef");
                _filterDef.setAccessible(true);
                Object filterDef = _filterDef.get(appFilterConfig);
                Class clsFilterDef = null;
                try {
                    // Tomcat 8
                    clsFilterDef = Class.forName("org.apache.tomcat.util.descriptor.web.FilterDef");
                } catch (Exception e) {
                    // Tomcat 7
                    clsFilterDef = Class.forName("org.apache.catalina.deploy.FilterDef");
                }
                Method removeFilterDef = standardContext.getClass().getDeclaredMethod("removeFilterDef", new Class[]{clsFilterDef});
                removeFilterDef.setAccessible(true);
                removeFilterDef.invoke(standardContext, filterDef);

                // org.apache.catalina.core.StandardContext#removeFilterMap
                Class clsFilterMap = null;
                try {
                    // Tomcat 8
                    clsFilterMap = Class.forName("org.apache.tomcat.util.descriptor.web.FilterMap");
                } catch (Exception e) {
                    // Tomcat 7
                    clsFilterMap = Class.forName("org.apache.catalina.deploy.FilterMap");
                }
                Object[] filterMaps = getFilterMaps(request);
                for (Object filterMap : filterMaps) {
                    Field _filterName = filterMap.getClass().getDeclaredField("filterName");
                    _filterName.setAccessible(true);
                    String filterName0 = (String) _filterName.get(filterMap);
                    if (filterName0.equals(filterName)) {
                        Method removeFilterMap = standardContext.getClass().getDeclaredMethod("removeFilterMap", new Class[]{clsFilterMap});
                        removeFilterDef.setAccessible(true);
                        removeFilterMap.invoke(standardContext, filterMap);
                    }
                }
            }

            public synchronized void deleteServlet(HttpServletRequest request, String servletName) throws Exception {
                HashMap<String, Object> childs = getChildren(request);
                Object objChild = childs.get(servletName);
                String urlPattern = null;
                HashMap<String, String> servletMaps = getServletMaps(request);
                for (Map.Entry<String, String> servletMap : servletMaps.entrySet()) {
                    if (servletMap.getValue().equals(servletName)) {
                        urlPattern = servletMap.getKey();
                        break;
                    }
                }

                if (urlPattern != null) {
                    // ???????????? org.apache.catalina.core.StandardContext#removeServletMapping
                    Object standardContext = getStandardContext(request);
                    Method removeServletMapping = standardContext.getClass().getDeclaredMethod("removeServletMapping", new Class[]{String.class});
                    removeServletMapping.setAccessible(true);
                    removeServletMapping.invoke(standardContext, urlPattern);
                    // Tomcat 6??????removeChild 789????????????
                    // ???????????? org.apache.catalina.core.StandardContext#removeChild
                    Method removeChild = standardContext.getClass().getDeclaredMethod("removeChild", new Class[]{org.apache.catalina.Container.class});
                    removeChild.setAccessible(true);
                    removeChild.invoke(standardContext, objChild);
                }
            }

            public synchronized void deleteWebsocket(HttpServletRequest request, String websocketName)throws Exception{
                WsServerContainer wsServerContainer = (WsServerContainer) request.getServletContext().getAttribute(ServerContainer.class.getName());

                // ?????????????????? WsServerContainer ????????????????????? configExactMatchMap
                Class<?> obj = Class.forName("org.apache.tomcat.websocket.server.WsServerContainer");
                Field field = obj.getDeclaredField("configExactMatchMap");
                field.setAccessible(true);
                Map<String, Object> configExactMatchMap = (Map<String, Object>) field.get(wsServerContainer);

                configExactMatchMap.remove(request.getParameter("websocketName"));
            }

            public synchronized HashMap<String, Object> getChildren(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _children = standardContext.getClass().getSuperclass().getDeclaredField("children");
                _children.setAccessible(true);
                HashMap<String, Object> children = (HashMap<String, Object>) _children.get(standardContext);
                return children;
            }


            public synchronized HashMap<String, String> getServletMaps(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _servletMappings = standardContext.getClass().getDeclaredField("servletMappings");
                _servletMappings.setAccessible(true);
                HashMap<String, String> servletMappings = (HashMap<String, String>) _servletMappings.get(standardContext);
                return servletMappings;
            }

            public synchronized List<Object> getListenerList(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _listenersList = standardContext.getClass().getDeclaredField("applicationEventListenersList");
                _listenersList.setAccessible(true);
                List<Object> listenerList = (CopyOnWriteArrayList) _listenersList.get(standardContext);
                return listenerList;
            }

            public synchronized Map getWebsocketList(javax.servlet.http.HttpServletRequest request) throws Exception{


                List<Object> websockets=new ArrayList<>();
                 String path="";
                Map map=new HashMap();
                WsServerContainer wsServerContainer = (WsServerContainer) request.getServletContext().getAttribute(ServerContainer.class.getName());

                // ?????????????????? WsServerContainer ????????????????????? configExactMatchMap
                Class<?> obj = Class.forName("org.apache.tomcat.websocket.server.WsServerContainer");
                Field field = obj.getDeclaredField("configExactMatchMap");
                field.setAccessible(true);
                Map<String, Object> configExactMatchMap = (Map<String, Object>) field.get(wsServerContainer);

                // ??????configExactMatchMap, ????????????????????? websocket ??????
                Set<String> keyset = configExactMatchMap.keySet();
                Iterator<String> iterator = keyset.iterator();
                while (iterator.hasNext()){
                    String key = iterator.next();

                    Object object = wsServerContainer.findMapping(key);


                    Class<?> wsMappingResultObj = Class.forName("org.apache.tomcat.websocket.server.WsMappingResult");
                    Field configField = wsMappingResultObj.getDeclaredField("config");
                    configField.setAccessible(true);
                    ServerEndpointConfig config1 = (ServerEndpointConfig)configField.get(object);
                    Class<?> clazz = config1.getEndpointClass();

       
                    Object ob= clazz.newInstance();
                    map.put(key,ob);
                }
                return map;
                // ???????????????name??? ???????????????????????????name?????????

            }

            public String getFilterName(Object filterMap) throws Exception {
                Method getFilterName = filterMap.getClass().getDeclaredMethod("getFilterName");
                getFilterName.setAccessible(true);
                return (String) getFilterName.invoke(filterMap, null);
            }

            public String[] getURLPatterns(Object filterMap) throws Exception {
                Method getFilterName = filterMap.getClass().getDeclaredMethod("getURLPatterns");
                getFilterName.setAccessible(true);
                return (String[]) getFilterName.invoke(filterMap, null);
            }


            String classFileIsExists(Class clazz) {
                if (clazz == null) {
                    return "class is null";
                }

                String className = clazz.getName();
                String classNamePath = className.replace(".", "/") + ".class";
                URL is = clazz.getClassLoader().getResource(classNamePath);
                if (is == null) {
                    return "????????????????????????class???????????????????????????";
                } else {
                    return is.getPath();
                }
            }

            String arrayToString(String[] str) {
                String res = "[";
                for (String s : str) {
                    res += String.format("%s,", s);
                }
                res = res.substring(0, res.length() - 1);
                res += "]";
                return res;
            }
        %>

        <%
            out.write("<h2>Tomcat memshell scanner 0.1.0</h2>");
            String action = request.getParameter("action");
            String filterName = request.getParameter("filterName");
            String servletName = request.getParameter("servletName");
            String className = request.getParameter("className");
            String websocketName = request.getParameter("websocketName");
            if (action != null && action.equals("kill") && filterName != null) {
                deleteFilter(request, filterName);
            } else if (action != null && action.equals("kill") && servletName != null) {
                deleteServlet(request, servletName);
            }else if (action != null && action.equals("kill") && websocketName != null){
                deleteWebsocket(request,websocketName);
            } else if (action != null && action.equals("dump") && className != null) {
                out.println(className);
                byte[] classBytes = Repository.lookupClass(Class.forName(className)).getBytes();
                response.addHeader("content-Type", "application/octet-stream");
                String filename = className + ".class";

                String agent = request.getHeader("User-Agent");
                if (agent.toLowerCase().indexOf("chrome") > 0) {
                    response.addHeader("content-Disposition", "attachment;filename=" + new String(filename.getBytes("UTF-8"), "ISO8859-1"));
                } else {
                    response.addHeader("content-Disposition", "attachment;filename=" + URLEncoder.encode(filename, "UTF-8"));
                }
                ServletOutputStream outDumper = response.getOutputStream();
                outDumper.write(classBytes, 0, classBytes.length);
                outDumper.close();
            } else {
                // Scan filter
                out.write("<h4>Filter scan result</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Filter name</th>\n" +
                        "        <th width=\"10%\">Patern</th>\n" +
                        "        <th width=\"20%\">Filter class</th>\n" +
                        "        <th width=\"20%\">Filter classLoader</th>\n" +
                        "        <th width=\"25%\">Filter class file path</th>\n" +
                        "        <th width=\"5%\">dump class</th>\n" +
                        "        <th width=\"5%\">kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                HashMap<String, Object> filterConfigs = getFilterConfig(request);
                Object[] filterMaps1 = getFilterMaps(request);
                for (int i = 0; i < filterMaps1.length; i++) {
                    out.write("<tr>");
                    Object fm = filterMaps1[i];
                    Object appFilterConfig = filterConfigs.get(getFilterName(fm));
                    if (appFilterConfig == null) {
                        continue;
                    }
                    Field _filter = appFilterConfig.getClass().getDeclaredField("filter");
                    _filter.setAccessible(true);
                    Object filter = _filter.get(appFilterConfig);
                    String filterClassName = filter.getClass().getName();
                    String filterClassLoaderName = filter.getClass().getClassLoader().getClass().getName();
                    // ID Filtername ???????????? className classLoader ????????????file dump kill
                    out.write(String.format("<td style=\"text-align:center\">%d</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td><td style=\"text-align:center\"><a href=\"?action=kill&filterName=%s\">kill</a></td>"
                            , i + 1
                            , getFilterName(fm)
                            , arrayToString(getURLPatterns(fm))
                            , filterClassName
                            , filterClassLoaderName
                            , classFileIsExists(filter.getClass())
                            , filterClassName
                            , getFilterName(fm)));
                    out.write("</tr>");
                }
                out.write("</tbody></table>");

                // Scan servlet
                out.write("<h4>Servlet scan result</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Servlet name</th>\n" +
                        "        <th width=\"10%\">Patern</th>\n" +
                        "        <th width=\"20%\">Servlet class</th>\n" +
                        "        <th width=\"20%\">Servlet classLoader</th>\n" +
                        "        <th width=\"25%\">Servlet class file path</th>\n" +
                        "        <th width=\"5%\">dump class</th>\n" +
                        "        <th width=\"5%\">kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                HashMap<String, Object> children = getChildren(request);
                Map<String, String> servletMappings = getServletMaps(request);

                int servletId = 0;
                for (Map.Entry<String, String> map : servletMappings.entrySet()) {
                    String servletMapPath = map.getKey();
                    String servletName1 = map.getValue();
                    StandardWrapper wrapper = (StandardWrapper) children.get(servletName1);

                    Class servletClass = null;
                    try {
                        servletClass = Class.forName(wrapper.getServletClass());
                    } catch (Exception e) {
                        Object servlet = wrapper.getServlet();
                        if (servlet != null) {
                            servletClass = servlet.getClass();
                        }
                    }
                    if (servletClass != null) {
                        out.write("<tr>");
                        String servletClassName = servletClass.getName();
                        String servletClassLoaderName = null;
                        try {
                            servletClassLoaderName = servletClass.getClassLoader().getClass().getName();
                        } catch (Exception e) {
                        }
                        out.write(String.format("<td style=\"text-align:center\">%d</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td><td style=\"text-align:center\"><a href=\"?action=kill&servletName=%s\">kill</a></td>"
                                , servletId + 1
                                , servletName1
                                , servletMapPath
                                , servletClassName
                                , servletClassLoaderName
                                , classFileIsExists(servletClass)
                                , servletClassName
                                , servletName1));
                        out.write("</tr>");
                    }
                    servletId++;
                }
                out.write("</tbody></table>");

                List<Object> listeners = getListenerList(request);
//                if (listeners == null || listeners.size() == 0) {
//                    return;
//                }
                out.write("<tbody>");
                List<ServletRequestListener> newListeners = new ArrayList<>();
                for (Object o : listeners) {
                    if (o instanceof ServletRequestListener) {
                        newListeners.add((ServletRequestListener) o);
                    }
                }

                // Scan listener
                out.write("<h4>Listener scan result</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"20%\">Listener class</th>\n" +
                        "        <th width=\"30%\">Listener classLoader</th>\n" +
                        "        <th width=\"35%\">Listener class file path</th>\n" +
                        "        <th width=\"5%\">dump class</th>\n" +
                        "        <th width=\"5%\">kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                int index = 0;
                for (ServletRequestListener listener : newListeners) {
                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td><td>%s</td><td>%s</td><td>%s</td><td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td><td style=\"text-align:center\"><a href=\"?action=kill&servletName=%s\">kill</a></td>"
                            , index + 1
                            , listener.getClass().getName()
                            , listener.getClass().getClassLoader()
                            , classFileIsExists(listener.getClass())
                            , listener.getClass().getName()
                            , listener.getClass().getName()));
                    out.write("</tr>");
                    index++;
                }
                out.write("</tbody></table>");


                Map websockets=getWebsocketList(request);
                out.println(websockets);
                if (websockets == null || websockets.size() == 0) {
                    return;
                }
                out.write("<tbody>");
                // Scan Websocket
                out.write("<h4>Websocket scan result</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"20%\">Websocket class</th>\n" +
                        "        <th width=\"30%\">Websocket classLoader</th>\n" +
                        "        <th width=\"35%\">Websocket Url path</th>\n" +
                        "        <th width=\"5%\">dump class</th>\n" +
                        "        <th width=\"5%\">kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                int index1 = 0;


                for (Object websocket : websockets.keySet()) {
                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td><td>%s</td><td>%s</td><td>%s</td><td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td><td style=\"text-align:center\"><a href=\"?action=kill&websocketName=%s\">kill</a></td>"
                            , index1 + 1
                            , websockets.get(websocket).getClass().getName()
                            , websockets.get(websocket).getClass().getClassLoader()
                            , websocket
                            , websockets.get(websocket).getClass().getName()+"$1"
                            , websocket));
                    out.write("</tr>");
                    index1++;
            }
            }

        %>
    </div>
    <br/>
    code by c0ny1
</center>
</body>
</html>
