// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract Staking {

    // Sabemos que es un token ERC-20 asi que lo dejaremos como IERC20
    // solo permitiremos este token ERC-20 
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;
    
    // haremos un seguimiento de las address que interactuan
    // la dejaremos como publica pero como buena practica lo correcto es: dejarla privada y crear una función accesadora
    // address -> cuanto han estakeado
    mapping(address => uint256) public s_balances;
    //mapping sobre cuanto ha pagado cada address
    mapping(address => uint256) public s_userRewardPerTokenPaid;
    // mapiing sobre cuando reward tiene cada address para reclamar
    mapping(address => uint256) public s_rewards;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    // Agregaremos este modificador de acceso a nuestras funciones
    // aqui se hace toda la matematica, se pone un poco confusa pero confien!!
    // luego estudienla y verán !!
    modifier updateReward(address account){
        // necesitamos saber:
        // reward por tokwne
        // ultimo timestamp / actualizacion
        // cada vez que alguien stakea, el monto a repartir cambia 
        // cada vez que alguien stakea en la linea de tiempo !!

        // Ejemplo
        // 5 sec = 1 persona ha stakeado 100 tokens = reward 500 tokens (100 x sec) 
        // 6 sec = 2 persona ha stakeado 100 tokens
        // cuanto le toca a cada uno en reward ???????
        // P1: 550 
        // P2: 50
        // 100 X 6 = 600 
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;

        // creamos un mapping para guardar los rewards
        // basado en el resultado de una funcion earned que haremos ahora !!
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount){        
        require(amount > 0, "Amount debe ser mayor que cero");
        _;
    }

    constructor(address stakingToken, address rewardToken){
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
    }
    //obtendremos el total reward de esta persona 
    function earned(address account) public view returns(uint256){
        // el balance actual de lo que han stakeado
        uint256 currentBalance = s_balances[account];
        // cuando ya han recivido 
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];

        uint256 totalEarned = ((currentBalance * (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;
        return totalEarned;

    }
    // basado en cuánto tiempo ha pasado durante esta instantánea más reciente
    function rewardPerToken() public view returns(uint256){
        if(s_totalSupply == 0){
            return s_rewardPerTokenStored;
        }

        return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }
    // external es mas barato que public en terminos de gas
    // podemos limitar mas tokenes pero solo aceptartemos uno
    // y lo inicializamos en el constructor
    function stake(uint256 amount) updateReward(msg.sender) moreThanZero(amount) external {
        // tendremos el registro de cuando el usuario ha stakeado
        // tener registro del total de tokens
        // transferir los tokens a este contrato
        s_balances[msg.sender] = s_balances[msg.sender] + amount;
        s_totalSupply = s_totalSupply + amount;
        // emitir evento
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed");        
    }

    // por qué utilizamos el modificar de acceso como publico ?
    // External es mas barato que public
    // con external estamos diciendo que solo cuentas o contratos externos a este mismo
    // contrato estaran llamando a la funcion
    function withdraw(uint256 amount) updateReward(msg.sender) moreThanZero(amount) external{
        s_balances[msg.sender] = s_balances[msg.sender] - amount;
        s_totalSupply = s_totalSupply - amount;
        bool success = s_stakingToken.transfer(msg.sender, amount);
        require(success, "Failed");
    }

    function claimReward() external updateReward(msg.sender) {
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        bool success = s_rewardToken.transfer(msg.sender, reward);
        require(success, "No hay reward para reclamar!");
        // cuando reward obtendrán?
        // aqui cada implementacion de reward es diferente
        // El mecanismo mas utilizado es que el contrato emite X tokens por segundo
        // y los reparte hacia todos los stakers !!

        // Tenemos que tener un mecanismo para que cada vez que alguien
        // deposite o haga un withdraw los tokens, se actualice cuanto reward tiene cada staker

    }


}