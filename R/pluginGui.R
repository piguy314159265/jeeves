#' Write Gui HTML for plugin
#' 
#' @param pluginDir directory containing the plugin.
#' @param htmlFile html file to write the Gui to
#' @param overrides a list of overrides for widgets 
#' @export
writeGuiHtml <- function(pluginDir = '.', htmlFile = NULL, overrides = NULL){
  dirs <- dirNames()
  pluginDir <- normalizePath(pluginDir)
  pluginName <- basename(pluginDir)
  if (is.null(htmlFile)){
    htmlFile <- file.path(pluginDir, sprintf("%sGui.html", pluginName))
  }
  yxmcFile <- file.path(
    pluginDir, dirs$macros, sprintf("%s.yxmc", pluginName)
  )
  layoutDir <- file.path(pluginDir, dirs$extras, 'Gui')
  if (!dir.exists(layoutDir)){
    dir.create(layoutDir)
  }
  layoutFile = file.path(layoutDir, 'layout.html.sample')
  x1 <- extractConfiguration(yxmcFile)
  x1b <- paste(
    c(
      "<fieldset>", 
      "<legend>Configuration</legend>",
      paste0("{{ ", "`", names(x1), "`", " }}"), 
      "</fieldset>\n"
    ), 
    collapse = '\n'
  )
  cat(x1b, file = layoutFile)
  ov <- file.path(pluginDir, dirs$extras, 'Gui', 'overrides.yaml')
  if (file.exists(ov)){
    overrides <- yaml::yaml.load_file(ov)
  }
  if (!is.null(overrides)){
    x1 <- modifyList(x1, overrides)
  }
  x2 <- makePage(x1)
  x3 <- makeGuiHtml(x2, pluginName = pluginName)
  # cat(as.character(x3), file = htmlFile)
  write_html(x3, htmlFile)
}

#' Write Gui HTML for plugin based on a layout
#' 
#' @inheritParams writeGuiHtml
#' @export
writeGuiHtmlFromLayout <- function(pluginDir = '.', htmlFile = NULL, 
    overrides = NULL){
  dirs <- dirNames()
  pluginDir <- normalizePath(pluginDir)
  pluginName <- basename(pluginDir)
  if (is.null(htmlFile)){
    htmlFile <- file.path(pluginDir, sprintf("%sGui.html", pluginName))
  }
  mylayout <- paste(
    readLines(file.path(pluginDir, dirs$extras, 'Gui', 'layout.html'), warn = F), 
    collapse = '\n'
  )
  yxmcFile <- file.path(
    pluginDir, dirs$macros, sprintf("%s.yxmc", pluginName)
  )
  x1 <- extractConfiguration(yxmcFile)
  ov <- file.path(pluginDir, dirs$extras, "Gui", "overrides.yaml")
  if (file.exists(ov)){
    overrides <- yaml::yaml.load_file(ov)
  }
  if (!is.null(overrides)){
    x1 <- modifyList(x1, overrides)
  }
  x1b <- lapply(seq_along(x1), function(i){
    x1[[i]]$id = names(x1)[i]
    x1[[i]]
  })
  names(x1b) <- names(x1)
  w = renderAyxWidgets(x1b)
  names(w) = names(x1b)
  
  htmlTextTemplate = function(...){
    htmlTemplate(text_ = mylayout, ...)
  }
  x2 <- do.call(htmlTextTemplate, w)
  x3 <- makeGuiHtml(x2, pluginName = pluginName)
  #cat(as.character(x3), file = htmlFile)
  write_html(x3, htmlFile)
}

write_html <- function(x, f){
  x3 <- gsub('&quot;', '"', as.character(x))
  cat(x3, file = f)
}

makeGuiHtml <- function(widgets, pluginName = "", template = NULL){
  if (is.null(template)) {
    template <- system.file(
      'templates', 'GuiTemplate.html', package = 'jeeves'
    )
  }
  gui <- htmltools::htmlTemplate(template, widgets = widgets, title = pluginName)
  return(gui)
}


ayxOption <- function(x){
  htmltools::tag('alteryx-option', x)
}

ayxWidgetWithProps <- function(x){
  d <- jsonlite::toJSON(Filter(Negate(is.null), x), auto_unbox = TRUE)
  htmltools::tag('alteryx-pluginwidget', list(`data-props` = d))
}

# yxmcFile <- system.file('templates', 'sample1.yxmc', package = 'jeeves')
# config <- extractConfiguration(yxmcFile)
# renderAyxWidgets(config)
renderAyxWidgets <- function(config){
  d2 <- lapply(seq_along(config), function(i){
    config[[i]]$dataName = names(config)[i]; 
    config[[i]]
  })
  do.call(tagList, lapply(d2, ayxPluginWidget))
}

renderAyxWidgets2 <- function(config){
  d2 <- lapply(seq_along(config), function(i){
    config[[i]]$dataName = names(config)[i]; 
    config[[i]]
  })
  lapply(d2, ayxPluginWidget)
}

makePage <- function(config, layout = NULL){
  config <- lapply(seq_along(config), function(i){
    config[[i]]$id = names(config)[i]
    config[[i]]$dataName = names(config)[i]; 
    config[[i]]
  })
  makeFieldSet <- function(x, id){
    tags$fieldset(id = id,
      tags$legend(id),
      do.call(tagList, lapply(x, function(x){
        d_ <- config[[x]]; d_$dataName = x;
        ayxPluginWidget(d_)
      }))             
    )
  }
  if (!is.null(layout)){
    layout <- yaml::yaml.load(layout)
    do.call(tagList, lapply(names(layout), function(k){
      makeFieldSet(layout[[k]], k)
    }))
  } else {
    tags$fieldset(
      tags$legend('Configuration'),
      do.call(tagList, lapply(config, ayxPluginWidget))
    ) 
  }
}

renderToggleBar <- function(d){
  div(class = 'clearfix togglebar', id = paste0('id-', d$group),
    div(class = 'label', style='float:left;', d$label),
    div(style = 'float:right;', div(class = 'toggletabs',
      lapply(names(d$values), function(k){
        cl = if (d$default == k) {
          'toggletab is-tab-selected' 
        } else {
          'toggletab'
        }
        div(class = cl, `data-page` = k, id = paste0('id-', k), d$values[[k]])
      })                                
    ))
  )
}

# Alteryx Plugin Widget
ayxPluginWidget = function(x){
  if (!is.null(x$type) && x$type == 'ToggleBar'){
    return(renderToggleBar(x))
  }
  if (!is.null(x$values)){
    values = lapply(seq_along(x$values), function(i){
      list(
        uiobject = localizeText(x$values[[i]]), 
        dataname = names(x$values)[i],
        default = if(!is.null(x$default)) {
          if(names(x$values)[[i]] == x$default) "true" else NULL
        } else {
          NULL
        }
      )
    })
    x[[length(x) + 1]] <- do.call(tagList, lapply(values, function(d){
      ayxOption(list(d$dataname, uiobject = d$uiobject, default = d$default))
    }))
    x$values <- NULL
    x$default <- NULL
  }
  label <- x$label
  if (!is.null(x$label)) x$label <- localizeText(x$label)
  if (!is.null(x$type) && x$type != 'NumericSlider') {
    x$label <- NULL
  } else {
    x$initialValue <- x$default
    x$default <- NULL
  }
  if (!is.null(x$type) && x$type == 'CheckBox'){
    x$defaultValue <- x$default
    x$default <- NULL
  }
  if ('text' %in% names(x)){
    x$text <- localizeText(x$text)
  }
  tagList(
    HTML(paste("<!-- ", x$dataName, " -->")),
    if (!(x$type %in% c('CheckBox', 'NumericSlider')) && !is.null(label) && label != "") {
      makeLabel(label, x$id)
    } else {
      NULL
    },
    tag('alteryx-pluginwidget', x)
  )
}

makeLabel <- function(label, id){
  # TODO uncomment this line once localization features are  in the build
  label <- sprintf('XMSG("%s")', label)
  tags$label(label, `for` = id)
}

localizeText <- function(text){
  sprintf('XMSG("%s")', text)
}

#' Render plugin widgets
#' 
#' @param pluginDir path to plugin directory
#' @param htmlFile layout file to use
#' @param overrides overrides if any
#' @param wrapInDiv boolean indicating if every widget should be wrapped in a div.
#' @export
renderPluginWidgets <- function(pluginDir = '.', htmlFile = NULL, 
    overrides = NULL, wrapInDiv = FALSE){
  dirs <- dirNames()
  pluginDir <- normalizePath(pluginDir)
  pluginName <- basename(pluginDir)
  if (is.null(htmlFile)){
    htmlFile <- file.path(pluginDir, sprintf("%sGui.html", pluginName))
  }
  yxmcFile <- file.path(
    pluginDir, dirs$macros, sprintf("%s.yxmc", pluginName)
  )
  x1 <- extractConfiguration(yxmcFile)
  ov <- file.path(pluginDir, dirs$extras, "Gui", "overrides.yaml")
  if (file.exists(ov)){
    overrides <- yaml::yaml.load_file(ov)
  }
  if (!is.null(overrides)){
    x1 <- modifyList(x1, overrides)
  }
  x1b <- lapply(seq_along(x1), function(i){
    x1[[i]]$id = names(x1)[i]
    x1[[i]]
  })
  names(x1b) <- names(x1)
  w = renderAyxWidgets2(x1b)
  names(w) = names(x1b)
  if (!wrapInDiv){
    return(w)
  } else {
    lapply(w, function(d){
      div(id = paste0('div-', makeHtmlId(d[[3]]$attribs$id)), d)
    })
  }
}
