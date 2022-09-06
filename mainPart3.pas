Program EVO;

Uses GraphABC;

type
  mtx = array [1..100, 1..100] of string;
  arr = array [1..1000] of mtx;
  
const
  C = 20; // размер ячейки
  W = 1920 div C; // ширина окна
  H = 1080 div C; // высота окна
  CELL = ' * ';
  DEAD = ' x ';
  BORN = ' o ';
  EMPTY = '    ';
  DOG = '@';
  
  
var
  dogX, dogY, minX, minY, maxX, maxY, cellCount:integer;
  lifeStart, borders: boolean;
  timeout: integer;// интервал смены поколений
  world: mtx;




procedure mouseDown(x,y,mb: integer);
begin
  
  SetPenWidth(5);  
  SetPenColor(Color.White);
  SetBrushColor(Color.White);  
  
  if (mb = 1) and (y >= 500) and (y <= 600) then    
    if (x >= 600) and (x <= 900) then
    begin
      DrawRectangle(600, 500, 900, 600);
      lifeStart:=true;
    end
    else if (x >= 1000) and (x <= 1300) then
    begin
      DrawRectangle(1000, 500, 1300, 600);
      borders:= true;
      lifeStart:=true;
    end;
  
end;

/// Выбор игрового поля
procedure chooseWorldType;
begin
  
  SetFontSize(26);  
  
  TextOut(570, 400, 'Выберите курсором мыши тип игрового поля:');
  
  SetBrushColor(Color.Aqua);
  
  Rectangle(600, 500, 900, 600);
  Rectangle(1000, 500, 1300, 600);  
  
  SetBrushColor(Color.Transparent);  
  SetFontColor(Color.FromArgb(10,0,30));
  
  TextOut(630, 530, 'Непрерывное');
  TextOut(1030, 530, 'Ограниченное');


  while not lifeStart do
    OnMouseDown:= MouseDown;
  sleep(200);
  SetFontColor(Color.White);
  Window.Init(-8,-8,W*C,H*C,Color.FromArgb(10,0,30));
end;


  
/// Вывод содержимого матрицы на поле
procedure render();
begin
  for var i:=1 to H-3 do
    for var j:=1 to W-2 do
    begin
      if world[i,j] = BORN then
        SetFontColor(Color.LightCyan)
      else if world[i,j] = CELL then
        SetFontColor(Color.Aqua)
      else if world[i,j] = DEAD then
        SetFontColor(Color.LightCoral);
      
      TextOut(j*C+5, i*C+4, world[i,j]);
    end;
end;



/// Управление собакой
procedure keyDown(k:integer);
begin
  if not lifeStart then
  begin
    
    TextOut(dogX*C+5, dogY*C+4, world[dogY, dogX]);
    
    case k of
      VK_NumPad8: if dogY-1 >= 1 then dogY -= 1;
      VK_NumPad4: if dogX-1 >= 1 then dogX -= 1;
      VK_NumPad2: if dogY+1 < H-2 then dogY += 1;
      VK_NumPad6: if dogX+1 < W-1 then dogX += 1;
      VK_Space:   lifeStart:=true;
      VK_Z:
      begin
        world[dogY, dogX] := CELL;
        cellCount+=1;
        if dogX < minX then
          minX:=dogX;
        if dogY < minY then
          minY:=dogY;
        if dogX > maxX then
          maxX:=dogX;
        if dogY > maxY then
          maxY:=dogY;
      end;
      VK_X:
      begin        
        world[dogY, dogX] := EMPTY;
        cellCount-=1;
      end;
    end;
    
    TextOut(dogX*C+5, dogY*C+2, DOG);
    
  end;
end;



/// Создание начальной конфигурации
procedure setConfig();
begin
  lifeStart:=false;
  SetPenColor(Color.FromArgb(150,30,0,80));
  SetPenWidth(1);
  SetFontSize(10);
  // Рисование сетки
  for var i:=1 to H do  
    Line(C, i*C, (W-1)*C, i*C);  
  for var i:=1 to W do  
    Line(i*C, C, i*C, (H-2)*C);

  SetPenWidth(39);
  // Рисование границ
  DrawRectangle(0, 0, W*C, (H-1)*C);
  
  
  // Заполоняем матрицу пустыми клетками
  for var i:=1 to H do
    for var j:=1 to W do
      world[i,j]:=EMPTY;
    
  // Создание собаки
  dogY:=H div 2;
  dogX:=W div 2;
  TextOut(dogX*C+5, dogY*C+2, DOG);
  
  while not lifeStart do
    OnKeyDown:= keyDown;
  render;  
end;



/// Возвращает кол-во соседей клетки
function findNeighbors(x,y:integer):integer;
var
  count,di,dj:integer;
  
begin
  
  for var i:=y-1 to y+1 do
    for var j:=x-1 to x+1 do
    begin

      di:=i;
      dj:=j;
      
      if not borders then
      begin 
        if (di < 1) then
          di := H-3
        else if di > H-3 then
          di := 1;
        
        if dj < 1 then
          dj := W-2
        else if dj > W-2 then
          dj := 1;
      end;
      
      if (dj > 0) and (di > 0) and (dj <= W-2) and (di <= H-3) and ((world[di,dj] = CELL) or (world[di,dj] = DEAD)) then
        count+=1;
        
    end;
        
    
  if (world[y,x] = CELL) or (world[y,x] = DEAD) then
    count-=1;
  
  Result:=count;
end;



procedure endOfLife(txt:string);
begin

  Window.Clear;
  Window.Init(-8,-8,W*C,H*C,Color.FromArgb(10,0,30));
  SetFontSize(32);
  TextOut(W*C div 2 - 110-txt.Length, H*C div 2 - 50, txt);
  
end;



/// Игровой процесс
procedure lifeProcess();
var
  nbs, len:integer;
  mtxConfs:arr;
begin
  timeout := 100;

  while true do
  begin
    
    sleep(timeout);
    
    minY-=1;
    if minY < 1 then
      maxY:=H-3;    
    minX-=1;
    if minX < 1 then
      maxX:=W-2;    
    maxY+=1;
    if maxY > H-3 then
      minY:=1;
    maxX+=1;
    if maxX > W-2 then
      minX:=1;
    
    for var i:= minY to maxY do
      for var j:= minX to maxX do
      begin
        
        nbs:=findNeighbors(j,i);

        if (nbs = 3) and (world[i,j] = EMPTY) then
        begin 
          world[i,j] := BORN;
          cellCount+=1;
          if j < minX then
            minX:=j;
          if i < minY then
            minY:=i;
          if j > maxX then
            maxX:=j;
          if i > maxY then
            maxY:=i;
        end
        else if ((nbs < 2) or (nbs > 3)) and (world[i,j] <> EMPTY) then
        begin
          world[i,j] := DEAD;
          cellCount-=1;
        end;
        
      end;
      
    render;
    sleep(timeout);
    
    for var i:=minY to maxY do
      for var j:=minX to maxX do
      begin
        
        if world[i,j] = BORN then
          world[i,j]:=CELL
        else if world[i,j] = DEAD then
          world[i,j]:=EMPTY;
        
      end;
    

    //Проверка на конец игры
    for var i:=1 to len do
      if world = mtxConfs[i] then
      begin
        if i = len then
          endOfLife('Стабильный мир')
        else
          endOfLife('Периодический мир c периодом в '+ (len-i+1));
        exit;
      end;
    if cellCount = 0 then
    begin
      endOfLife('Мертвый мир');
      exit;
    end;
    
    
    if len = 1000 then
      len:=0;
    
    len+=1;
    mtxConfs[len]:=world;    
    
    Render;
    
  end;
end;


Begin
  Window.Init(-8,-8,W*C,H*C,Color.FromArgb(10,0,30));
  SetFontColor(Color.Aqua);
  
  minX:=W;
  minY:=H;

  chooseWorldType;  

  setConfig;
  
  lifeProcess;  
  
end.