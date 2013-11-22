<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/head.inc';
?>
<body>
<?php
  @include $_SERVER['DOCUMENT_ROOT']. '/inc/breakpoint_debug.inc';
?>
<header class="header" role="banner">
  <div class="header--inner">
    <a href="/" class="logo--link"><img src="logo.png" alt="" class="logo--image"></a>
    <nav class="nav">
      <a href="#" title="Min konto" class="nav--link">
        <i class="icon-user"></i>
        <span class="nav--text">Min konto</span>
      </a>
      <a href="#" title="Notifikationer" class="nav--link-mail">
        <i class="icon-mail"></i>
        <span class="nav--text">Notifikationer</span>
        <span class="notification">3</span>
      </a>
      <a href="#" title="Menu" class="nav--link-menu">
        <i class="icon-menu"></i>
        <span class="nav--text">Menu</span>
      </a>
    </nav>
  </div>
</header>
<div class="search">
  <div class="search--inner">
    <form>
      <label class="form-label">Søg efter svar</label>
      <div class="search--field-wrapper">
        <i class="search--icon icon-search"></i>
        <input type="text" placeholder="Skriv f.eks. &quot;Hvordan dokumenteres delvis aktindsigt&quot;" value="Hvordan dokumenteres delvis aktindsigt" class="search--field">
        <input type="submit" class="search--button" value="Søg">
      </div>
    </form>
  </div>
</div>
<div class="search-result">
  <div class="search-result--inner">
    <div class="search-result--question">Dit spørgsmål: <strong>&quot;Hvordan dokumenteres delvis aktindsigt&quot;</strong></div>
    <ul class="content-list">
      <li class="content-list--item">
        <h4><a href="question.php">Hvordan dokumenteres delvis aktindsigt? Og findes der en vejledning i dokumentation af aktindsigt?</a></h4>
        <div>Nej der er ikke en selvstændig vejledning i aktindsigt. Under aktindsigt (i Stamdata) kan Status sættes til Delvis bevilliget samt i bemærkningen kan dokumenteres hvilken sag det omfatter.</div>
      </li>
      <li class="content-list--item">
        <h4><a href="question.php">Ved ordinationer fra egen læge på instruktion i PEP-fløjte, hvilke ydelser kan man bruge til dette?</a></h4>
        <div>Man giver en Træningsydelse.</div>
      </li>
      <li class="content-list--item">
        <h4><a href="question.php">Er det tilstrækkeligt i forhold til sygeplejefaglig udredning, at en ydelse er tildelt og at de 12 sygeplejefaglige målepunkter er udfyldt under Samlet faglig vurdering?</a></h4>
        <div>Nej, ved en sundhedsfagligindsats skal der være et fokusområde. Se vejledning for Samlet faglig vurdering og vejledningen for Fokusområder.</div>
      </li>
      <li class="content-list--item is-last">
        <h4><a href="question.php">Skal terapeuter i plejebolig oprette ydelser under sagsark ”træning” eller sagsark ”visitation i plejebolig”?</a></h4>
        <div>De skal oprettes på sagsarket ‘træning’ med dertilhørende specialark ‘træning’.</div>
      </li>
    </ul>
  </div>
  <div>Fandt du ikke svar på dit spørgsmål? <a href="#">Opret dit spørgsmål her</a></div>
</div>
</body>
</html>